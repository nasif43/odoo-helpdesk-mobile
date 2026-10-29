# -*- coding: utf-8 -*-
from odoo import fields
from odoo.tests.common import TransactionCase
from odoo.exceptions import AccessError

class TestHelpdeskMobileApi(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.admin_user = cls.env['res.users'].search([('login', '=', 'admin@helpdesk.local')], limit=1)
        cls.cust1_user = cls.env['res.users'].search([('login', '=', 'customer1@acme.com')], limit=1)
        cls.cust2_user = cls.env['res.users'].search([('login', '=', 'customer2@globex.com')], limit=1)
        cls.team = cls.env['helpdesk.team'].search([('name', '=', 'Customer Support')], limit=1)
        cls.stage_new = cls.env['helpdesk.stage'].search([('name', '=', 'New'), ('team_ids', 'in', [cls.team.id])], limit=1)
        cls.stage_approved = cls.env['helpdesk.stage'].search([('name', '=', 'Approved'), ('team_ids', 'in', [cls.team.id])], limit=1)
        cls.stage_done = cls.env['helpdesk.stage'].search([('name', '=', 'Done'), ('team_ids', 'in', [cls.team.id])], limit=1)

    def test_01_token_generation_and_roles(self):
        """Test token creation and role mapping"""
        token_model = self.env['helpdesk.mobile.token']
        admin_tokens = token_model.create_token_pair(self.admin_user)
        self.assertEqual(admin_tokens['user']['role'], 'admin')
        self.assertTrue(admin_tokens['access_token'])

        cust_tokens = token_model.create_token_pair(self.cust1_user)
        self.assertEqual(cust_tokens['user']['role'], 'customer')

        # Verify token retrieval
        verified_user = token_model.verify_token(admin_tokens['access_token'])
        self.assertEqual(verified_user.id, self.admin_user.id)

    def test_02_customer_data_isolation(self):
        """Customer sees only their own tickets"""
        cust1_env = self.env(user=self.cust1_user)
        tickets = cust1_env['helpdesk.ticket'].search([])
        for t in tickets:
            self.assertEqual(t.partner_id.id, self.cust1_user.partner_id.id,
                             "Customer 1 should only see tickets belonging to their partner!")

    def test_03_admin_only_custom_field_hidden_from_customer(self):
        """Admin-only custom field (x_estimated_cost) is hidden from customer schema and payloads"""
        field_config_model = self.env['helpdesk.mobile.field.config']
        
        customer_schema = field_config_model.get_schema_for_role(role='customer')
        customer_field_names = [f['name'] for f in customer_schema['fields']]
        self.assertNotIn('x_estimated_cost', customer_field_names,
                         "Admin-only field x_estimated_cost MUST NOT appear in customer schema!")
        self.assertIn('x_site_location', customer_field_names)

        admin_schema = field_config_model.get_schema_for_role(role='admin')
        admin_field_names = [f['name'] for f in admin_schema['fields']]
        self.assertIn('x_estimated_cost', admin_field_names)

        # Check ticket to_mobile_dict payload
        ticket = self.env['helpdesk.ticket'].search([('partner_id', '=', self.cust1_user.partner_id.id)], limit=1)
        cust_payload = ticket.to_mobile_dict(self.cust1_user, detail=True)
        self.assertNotIn('x_estimated_cost', cust_payload['custom'],
                         "Customer payload MUST NOT leak admin-only custom fields!")

        admin_payload = ticket.to_mobile_dict(self.admin_user, detail=True)
        self.assertIn('x_estimated_cost', admin_payload['custom'])

    def test_04_allowed_actions_by_stage_and_role(self):
        """Verify allowed_actions are properly governed by stage and role"""
        ticket_new = self.env['helpdesk.ticket'].create({
            'name': 'Test New Ticket',
            'team_id': self.team.id,
            'stage_id': self.stage_new.id,
            'partner_id': self.cust1_user.partner_id.id,
        })

        admin_actions = ticket_new.get_allowed_actions(self.admin_user)
        self.assertIn('approve', admin_actions)
        self.assertIn('reject', admin_actions)
        self.assertIn('assign', admin_actions)

        cust_actions = ticket_new.get_allowed_actions(self.cust1_user)
        self.assertNotIn('approve', cust_actions)
        self.assertNotIn('reject', cust_actions)
        self.assertIn('reply', cust_actions)

    def test_05_reopen_window_validation(self):
        """Reopen is allowed on closed tickets within the window"""
        ticket_done = self.env['helpdesk.ticket'].create({
            'name': 'Test Done Ticket',
            'team_id': self.team.id,
            'stage_id': self.stage_done.id,
            'partner_id': self.cust1_user.partner_id.id,
            'closed_at': fields.Datetime.now(),
        })

        cust_actions = ticket_done.get_allowed_actions(self.cust1_user)
        self.assertIn('reopen', cust_actions)
        self.assertIn('rate', cust_actions)
        self.assertNotIn('reply', cust_actions)  # Regular reply disabled on closed ticket
