#!/usr/bin/env python3
"""
seed_demo_data.py: Seeds demo data for the Odoo Helpdesk Mobile app in odoo_helpdesk_db.
Populates:
- 7 sequential stages (New, Approved, Tracking, Work In Progress, Solving, Done, Rejected)
- Tags
- 1 Admin user (helpdesk.group_helpdesk_manager)
- 2 Portal customer users
- Sample custom fields on helpdesk.ticket
- Sample tickets across multiple stages
"""

import sys
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("seed_demo_data")

def run_seed(env):
    logger.info("Starting demo data seeding on database: %s", env.cr.dbname)

    # ----------------------------------------------------------------------
    # 1. Primary Helpdesk Team & 7 Stages
    # ----------------------------------------------------------------------
    team = env['helpdesk.team'].search([('name', '=', 'Customer Support')], limit=1)
    if not team:
        team = env['helpdesk.team'].search([], limit=1)
    if not team:
        team = env['helpdesk.team'].create({
            'name': 'Customer Support',
            'use_sla': True,
            'use_rating': True,
        })
        logger.info("Created helpdesk team: %s (ID %s)", team.name, team.id)
    else:
        logger.info("Using existing helpdesk team: %s (ID %s)", team.name, team.id)

    stages_spec = [
        {"name": "New", "sequence": 1, "fold": False},
        {"name": "Approved", "sequence": 2, "fold": False},
        {"name": "Tracking", "sequence": 3, "fold": False},
        {"name": "Work In Progress", "sequence": 4, "fold": False},
        {"name": "Solving", "sequence": 5, "fold": False},
        {"name": "Done", "sequence": 6, "fold": True},
        {"name": "Rejected", "sequence": 7, "fold": True},
    ]

    stage_map = {}
    for s in stages_spec:
        stage = env['helpdesk.stage'].search([
            ('name', '=', s['name']),
            ('team_ids', 'in', [team.id])
        ], limit=1)
        if not stage:
            stage = env['helpdesk.stage'].create({
                'name': s['name'],
                'sequence': s['sequence'],
                'fold': s['fold'],
                'team_ids': [(4, team.id)],
            })
            logger.info("Created stage: %s (Seq %s, Fold %s)", s['name'], s['sequence'], s['fold'])
        else:
            stage.write({
                'sequence': s['sequence'],
                'fold': s['fold'],
            })
        if 'is_close' in stage._fields:
            stage.write({'is_close': (s['name'] in ['Done', 'Rejected'])})
        stage_map[s['name']] = stage

    # ----------------------------------------------------------------------
    # 2. Tags
    # ----------------------------------------------------------------------
    tag_names = ["Urgent", "Frontend", "Backend", "VIP", "Hardware", "Bug", "Question", "Request"]
    tag_records = {}
    for tg in tag_names:
        tag = env['helpdesk.tag'].search([('name', '=', tg)], limit=1)
        if not tag:
            tag = env['helpdesk.tag'].create({'name': tg})
        tag_records[tg] = tag

    # ----------------------------------------------------------------------
    # 3. Users: Admin & 2 Portal Customers
    # ----------------------------------------------------------------------
    group_portal = env.ref('base.group_portal')
    group_user = env.ref('base.group_user')
    group_helpdesk_mgr = env.ref('helpdesk.group_helpdesk_manager', raise_if_not_found=False)
    group_helpdesk_user = env.ref('helpdesk.group_helpdesk_user', raise_if_not_found=False)

    # 3A. Helpdesk Admin User
    admin_email = "admin@helpdesk.local"
    admin_user = env['res.users'].search([('login', '=', admin_email)], limit=1)
    admin_groups = [group_user.id]
    if group_helpdesk_mgr:
        admin_groups.append(group_helpdesk_mgr.id)
    if group_helpdesk_user:
        admin_groups.append(group_helpdesk_user.id)

    if not admin_user:
        admin_partner = env['res.partner'].create({
            'name': 'Business Owner / Helpdesk Admin',
            'email': admin_email,
            'phone': '+8801700000001',
        })
        admin_user = env['res.users'].create({
            'name': 'Business Owner',
            'login': admin_email,
            'partner_id': admin_partner.id,
            'group_ids': [(6, 0, admin_groups)],
        })
        admin_user.password = "admin123"
        logger.info("Created Admin user: %s (password: admin123)", admin_email)
    else:
        admin_user.group_ids = [(6, 0, admin_groups)]
        admin_user.password = "admin123"

    # Ensure admin is member of the team
    if admin_user.id not in team.member_ids.ids:
        team.write({'member_ids': [(4, admin_user.id)]})

    # 3B. Portal Customer 1
    cust1_email = "customer1@acme.com"
    cust1_user = env['res.users'].search([('login', '=', cust1_email)], limit=1)
    if not cust1_user:
        cust1_partner = env['res.partner'].create({
            'name': 'John Doe (Acme Corp)',
            'email': cust1_email,
            'phone': '+8801700000002',
            'is_company': False,
        })
        cust1_user = env['res.users'].create({
            'name': 'John Doe',
            'login': cust1_email,
            'partner_id': cust1_partner.id,
            'group_ids': [(6, 0, [group_portal.id])],
        })
        cust1_user.password = "customer123"
        logger.info("Created Customer 1: %s (password: customer123)", cust1_email)
    else:
        cust1_user.password = "customer123"

    # 3C. Portal Customer 2
    cust2_email = "customer2@globex.com"
    cust2_user = env['res.users'].search([('login', '=', cust2_email)], limit=1)
    if not cust2_user:
        cust2_partner = env['res.partner'].create({
            'name': 'Jane Smith (Globex Corp)',
            'email': cust2_email,
            'phone': '+8801700000003',
            'is_company': False,
        })
        cust2_user = env['res.users'].create({
            'name': 'Jane Smith',
            'login': cust2_email,
            'partner_id': cust2_partner.id,
            'group_ids': [(6, 0, [group_portal.id])],
        })
        cust2_user.password = "customer123"
        logger.info("Created Customer 2: %s (password: customer123)", cust2_email)
    else:
        cust2_user.password = "customer123"

    # ----------------------------------------------------------------------
    # 4. Sample Custom Fields on helpdesk.ticket
    # ----------------------------------------------------------------------
    model_ticket = env['ir.model'].search([('model', '=', 'helpdesk.ticket')], limit=1)
    if model_ticket:
        custom_fields = [
            {
                'name': 'x_site_location',
                'field_description': 'Site Location',
                'ttype': 'selection',
                'selection_ids': [
                    (0, 0, {'value': 'hq', 'name': 'Headquarters', 'sequence': 1}),
                    (0, 0, {'value': 'branch_dhaka', 'name': 'Dhaka Branch', 'sequence': 2}),
                    (0, 0, {'value': 'branch_ctg', 'name': 'Chittagong Branch', 'sequence': 3}),
                    (0, 0, {'value': 'remote', 'name': 'Remote Site', 'sequence': 4}),
                ]
            },
            {
                'name': 'x_urgency_notes',
                'field_description': 'Urgency Notes',
                'ttype': 'text',
            },
            {
                'name': 'x_requires_onsite',
                'field_description': 'Requires On-Site Visit',
                'ttype': 'boolean',
            },
            {
                'name': 'x_incident_date',
                'field_description': 'Incident Date',
                'ttype': 'date',
            },
            {
                'name': 'x_estimated_cost',
                'field_description': 'Estimated Cost',
                'ttype': 'monetary',
            },
        ]

        for cf in custom_fields:
            existing = env['ir.model.fields'].search([
                ('model_id', '=', model_ticket.id),
                ('name', '=', cf['name'])
            ], limit=1)
            if not existing:
                field_vals = {
                    'model_id': model_ticket.id,
                    'name': cf['name'],
                    'field_description': cf['field_description'],
                    'ttype': cf['ttype'],
                    'state': 'manual',
                }
                if 'selection_ids' in cf:
                    field_vals['selection_ids'] = cf['selection_ids']
                env['ir.model.fields'].create(field_vals)
                logger.info("Created custom field %s on helpdesk.ticket", cf['name'])

    # ----------------------------------------------------------------------
    # 5. Sample Tickets across Stages
    # ----------------------------------------------------------------------
    existing_tickets = env['helpdesk.ticket'].search_count([])
    if existing_tickets < 5:
        sample_tickets = [
            {
                'name': 'Cannot access customer inventory portal',
                'description': '<p>Getting 504 gateway timeout when querying inventory stock.</p>',
                'partner_id': cust1_user.partner_id.id,
                'team_id': team.id,
                'stage_id': stage_map['New'].id,
                'tag_ids': [(4, tag_records['Bug'].id), (4, tag_records['Backend'].id)],
                'priority': '2',
            },
            {
                'name': 'Printer offline in Accounts department',
                'description': '<p>Network printer not responding to ping or print jobs.</p>',
                'partner_id': cust1_user.partner_id.id,
                'team_id': team.id,
                'user_id': admin_user.id,
                'stage_id': stage_map['Work In Progress'].id,
                'tag_ids': [(4, tag_records['Hardware'].id)],
                'priority': '1',
            },
            {
                'name': 'Switch port flapping in Server Room',
                'description': '<p>Port 24 is dropping packets intermittently.</p>',
                'partner_id': cust1_user.partner_id.id,
                'team_id': team.id,
                'user_id': admin_user.id,
                'stage_id': stage_map['Solving'].id,
                'tag_ids': [(4, tag_records['Urgent'].id)],
                'priority': '3',
            },
            {
                'name': 'New ergonomic mouse request',
                'description': '<p>Requesting vertical mouse for UX design work.</p>',
                'partner_id': cust2_user.partner_id.id,
                'team_id': team.id,
                'user_id': admin_user.id,
                'stage_id': stage_map['Done'].id,
                'tag_ids': [(4, tag_records['Request'].id)],
                'priority': '0',
            },
            {
                'name': 'Request for company sponsored iPad Pro',
                'description': '<p>Need personal tablet for leisure reading.</p>',
                'partner_id': cust2_user.partner_id.id,
                'team_id': team.id,
                'stage_id': stage_map['Rejected'].id,
                'tag_ids': [(4, tag_records['Request'].id)],
                'priority': '0',
            },
        ]
        for t_data in sample_tickets:
            ticket = env['helpdesk.ticket'].create(t_data)
            logger.info("Created sample ticket '%s' in stage %s (ID %s)", ticket.name, ticket.stage_id.name, ticket.id)

    env.cr.commit()
    logger.info("✅ Demo data seed completed successfully!")

if 'env' in locals():
    run_seed(env)
else:
    ODOO_PATH = "/home/muhts/dev/Codes/metamorphosis/odoo/odoo"
    CONFIG_PATH = "/home/muhts/dev/Codes/metamorphosis/odoo-app/odoo.conf"
    DB_NAME = "odoo_helpdesk_db"

    if ODOO_PATH not in sys.path:
        sys.path.insert(0, ODOO_PATH)

    import odoo
    from odoo import api, SUPERUSER_ID
    from odoo.tools import config
    from odoo.modules.registry import Registry

    config.parse_config(["-c", CONFIG_PATH, "-d", DB_NAME])
    registry = Registry(DB_NAME)
    with registry.cursor() as cr:
        env = api.Environment(cr, SUPERUSER_ID, {})
        run_seed(env)
