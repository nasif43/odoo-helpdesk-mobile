# -*- coding: utf-8 -*-
from datetime import timedelta
from odoo import models, fields, api

class HelpdeskTicket(models.Model):
    _inherit = 'helpdesk.ticket'

    currency_id = fields.Many2one(
        'res.currency',
        string='Currency',
        default=lambda self: self.env.company.currency_id
    )
    rejection_reason = fields.Text(string='Rejection Reason', help='Reason provided by admin when declining ticket')
    closed_at = fields.Datetime(string='Closed Date', readonly=True)
    employee_id = fields.Many2one('hr.employee', string='Assigned Employee', tracking=True)

    @api.model_create_multi
    def create(self, vals_list):
        for vals in vals_list:
            if vals.get('employee_id') and not vals.get('user_id'):
                emp = self.env['hr.employee'].sudo().browse(vals['employee_id'])
                if emp.user_id:
                    vals['user_id'] = emp.user_id.id
            elif vals.get('user_id') and not vals.get('employee_id'):
                emp = self.env['hr.employee'].sudo().search([('user_id', '=', vals['user_id'])], limit=1)
                if emp:
                    vals['employee_id'] = emp.id
        return super().create(vals_list)

    def write(self, vals):
        # Sync employee_id and user_id
        if 'employee_id' in vals:
            emp_id = vals.get('employee_id')
            if emp_id and 'user_id' not in vals:
                emp = self.env['hr.employee'].sudo().browse(emp_id)
                if emp.user_id:
                    vals['user_id'] = emp.user_id.id
            elif not emp_id and 'user_id' not in vals:
                vals['user_id'] = False
        elif 'user_id' in vals and 'employee_id' not in vals:
            uid = vals.get('user_id')
            if uid:
                emp = self.env['hr.employee'].sudo().search([('user_id', '=', uid)], limit=1)
                if emp:
                    vals['employee_id'] = emp.id
            else:
                vals['employee_id'] = False

        # Track closing date when moving to closed stage
        if 'stage_id' in vals:
            new_stage = self.env['helpdesk.stage'].browse(vals['stage_id'])
            if new_stage.is_close or new_stage.fold:
                vals['closed_at'] = fields.Datetime.now()
        return super().write(vals)

    def get_allowed_actions(self, user):
        self.ensure_one()
        is_admin = user.has_group('helpdesk.group_helpdesk_manager')
        actions = []
        is_closed = self.stage_id.is_close or self.stage_id.fold or (self.stage_id.name in ['Done', 'Rejected'])

        if is_admin:
            actions.extend(['change_stage', 'assign', 'edit_details', 'internal_note', 'reply'])
            if self.stage_id.name == 'New':
                actions.extend(['approve', 'reject'])
        else:
            # Customer actions
            if not is_closed:
                actions.append('reply')
                if self.stage_id.name in ['Solving', 'Done']:
                    actions.append('confirm')
            else:
                # Reopen allowed within 7 days from Solving or Done
                reopen_window_days = 7
                if self.closed_at and (fields.Datetime.now() - self.closed_at).days <= reopen_window_days:
                    actions.append('reopen')
                elif not self.closed_at:
                    actions.append('reopen')
                if self.stage_id.name == 'Done':
                    actions.append('rate')

        return actions

    def to_mobile_dict(self, user, detail=False):
        self.ensure_one()
        is_admin = user.has_group('helpdesk.group_helpdesk_manager')
        role = 'admin' if is_admin else 'customer'

        stage_data = {
            'id': self.stage_id.id,
            'name': self.stage_id.name,
            'sequence': self.stage_id.sequence,
            'is_closed': bool(self.stage_id.is_close or self.stage_id.fold or (self.stage_id.name in ['Done', 'Rejected'])),
        }

        assignee_data = None
        emp = self.sudo().employee_id
        if not emp and self.sudo().user_id:
            emp = self.env['hr.employee'].sudo().search([('user_id', '=', self.sudo().user_id.id)], limit=1)
        if emp:
            emp_sudo = emp.sudo()
            assignee_data = {
                'id': emp_sudo.id,
                'name': emp_sudo.name,
                'job_title': emp_sudo.job_title or 'Helpdesk Specialist',
                'department': emp_sudo.department_id.name if emp_sudo.department_id else 'Support Operations',
                'email': emp_sudo.work_email or (emp_sudo.user_id.email if emp_sudo.user_id else ''),
                'phone': emp_sudo.work_phone or '',
            }
        elif self.sudo().user_id:
            u_sudo = self.sudo().user_id
            assignee_data = {
                'id': u_sudo.id,
                'name': u_sudo.name,
                'job_title': 'Support Agent',
                'department': 'Support Operations',
                'email': u_sudo.email or '',
                'phone': '',
            }

        customer_data = None
        if self.partner_id:
            customer_data = {
                'id': self.partner_id.id,
                'name': self.partner_id.name,
                'email': self.partner_id.email or '',
                'phone': self.partner_id.phone or '',
            }

        # Extract exposed custom fields
        custom_dict = {}
        field_configs = self.env['helpdesk.mobile.field.config'].sudo().search([
            ('active', '=', True)
        ])
        for cfg in field_configs:
            # Enforce visibility: never expose admin-only custom fields to customer
            if not is_admin and cfg.visible_to == 'admin':
                continue
            fname = cfg.name
            if fname in self._fields:
                val = self.sudo()[fname]
                ftype = cfg.ttype
                if ftype == 'selection':
                    # Return value and label
                    selection_dict = dict(self._fields[fname].selection or [])
                    custom_dict[fname] = {'value': val, 'label': selection_dict.get(val, val)} if val else None
                elif ftype in ['many2one']:
                    custom_dict[fname] = {'id': val.id, 'name': val.display_name} if val else None
                elif ftype in ['many2many']:
                    custom_dict[fname] = [{'id': r.id, 'name': r.display_name} for r in val]
                elif ftype in ['date', 'datetime']:
                    custom_dict[fname] = str(val) if val else None
                elif ftype in ['char', 'text']:
                    custom_dict[fname] = str(val) if val else ''
                elif ftype == 'boolean':
                    custom_dict[fname] = bool(val)
                else:
                    custom_dict[fname] = val

        data = {
            'id': self.id,
            'number': f"#{self.id}",
            'subject': self.name,
            'stage': stage_data,
            'priority': int(self.priority or 0),
            'assignee': assignee_data,
            'customer': customer_data,
            'tags': [{'id': t.id, 'name': t.name} for t in self.sudo().tag_ids],
            'created_at': self.create_date.isoformat() if self.create_date else None,
            'updated_at': self.write_date.isoformat() if self.write_date else None,
            'allowed_actions': self.get_allowed_actions(user),
            'custom': custom_dict,
        }

        if detail:
            data['description'] = self.description or ''
            data['rejection_reason'] = self.rejection_reason or ''
            data['closed_at'] = self.closed_at.isoformat() if self.closed_at else None
            # Attachments
            attachments = self.env['ir.attachment'].sudo().search([
                ('res_model', '=', 'helpdesk.ticket'),
                ('res_id', '=', self.id)
            ])
            data['attachments'] = [{
                'id': att.id,
                'name': att.name,
                'mimetype': att.mimetype,
                'size': att.file_size,
                'url': f"/api/mobile/v1/attachments/{att.id}",
            } for att in attachments]

        return data
