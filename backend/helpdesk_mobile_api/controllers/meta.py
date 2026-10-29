# -*- coding: utf-8 -*-
from odoo import http
from odoo.http import request
from .common import json_response, error_response, require_auth

class MobileMetaController(http.Controller):

    @http.route('/api/mobile/v1/meta/stages', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth()
    def get_stages(self, current_user, is_admin):
        # Fetch stages from Customer Support team (matching Odoo web Helpdesk kanban)
        team = request.env['helpdesk.team'].sudo().search([('name', '=', 'Customer Support')], limit=1)
        if not team:
            team = request.env['helpdesk.team'].sudo().search([], limit=1)
        stages = team.stage_ids.sorted('sequence') if team else request.env['helpdesk.stage'].sudo().search([('active', '=', True)], order='sequence, id')
        stage_list = []
        for s in stages:
            is_closed = bool(s.is_close or s.fold or (s.name in ['Done', 'Rejected']))
            stage_list.append({
                'id': s.id,
                'name': s.name,
                'sequence': s.sequence,
                'is_closed': is_closed,
                'fold': bool(s.fold),
            })
        return json_response(stage_list)

    @http.route('/api/mobile/v1/meta/ticket-types', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth()
    def get_ticket_types(self, current_user, is_admin):
        # Standard types (or from model if installed)
        types = [
            {'id': 1, 'name': 'Bug / Issue'},
            {'id': 2, 'name': 'Question'},
            {'id': 3, 'name': 'Feature Request'},
            {'id': 4, 'name': 'General Inquiry'},
        ]
        return json_response(types)

    @http.route('/api/mobile/v1/meta/tags', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth()
    def get_tags(self, current_user, is_admin):
        tags = request.env['helpdesk.tag'].sudo().search([], order='name')
        return json_response([{'id': t.id, 'name': t.name} for t in tags])

    @http.route('/api/mobile/v1/meta/priorities', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth()
    def get_priorities(self, current_user, is_admin):
        priorities = [
            {'value': 0, 'label': 'Normal'},
            {'value': 1, 'label': 'Low'},
            {'value': 2, 'label': 'High'},
            {'value': 3, 'label': 'Urgent'},
        ]
        return json_response(priorities)

    @http.route('/api/mobile/v1/meta/agents', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth(role='admin')
    def get_agents(self, current_user, is_admin):
        # Query active employees for helpdesk agent assignment
        employees = request.env['hr.employee'].sudo().search([('active', '=', True)], order='name')
        agents = []
        for emp in employees:
            open_count = request.env['helpdesk.ticket'].sudo().search_count([
                '|', ('employee_id', '=', emp.id), ('user_id', '=', emp.user_id.id if emp.user_id else 0),
                ('stage_id.fold', '=', False),
            ])
            agents.append({
                'id': emp.id,
                'name': emp.name,
                'job_title': emp.job_title or 'Helpdesk Specialist',
                'department': emp.department_id.name if emp.department_id else 'Support Operations',
                'email': emp.work_email or (emp.user_id.email if emp.user_id else ''),
                'phone': emp.work_phone or '',
                'open_tickets_count': open_count,
            })
        return json_response(agents)

    @http.route('/api/mobile/v1/meta/config', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth()
    def get_config(self, current_user, is_admin):
        params = request.env['ir.config_parameter'].sudo()
        reopen_days = int(params.get_param('helpdesk_mobile.reopen_window_days', 7))
        max_size = int(params.get_param('helpdesk_mobile.max_attachment_size_mb', 10))
        max_count = int(params.get_param('helpdesk_mobile.max_attachments_count', 5))

        role = 'admin' if is_admin else 'customer'
        schema_info = request.env['helpdesk.mobile.field.config'].sudo().get_schema_for_role(role=role)

        data = {
            'max_attachment_size_mb': max_size,
            'max_attachments_count': max_count,
            'reopen_window_days': reopen_days,
            'features': {
                'customer_ratings': True,
                'customer_registration': True,
                'offline_queue': True,
            },
            'fields_schema_version': schema_info['version'],
        }
        return json_response(data)

    @http.route('/api/mobile/v1/meta/ticket-fields', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth()
    def get_ticket_fields(self, current_user, is_admin):
        role = 'admin' if is_admin else 'customer'
        schema_data = request.env['helpdesk.mobile.field.config'].sudo().get_schema_for_role(role=role)
        etag = f'"{schema_data["version"]}"'

        client_etag = request.httprequest.headers.get('If-None-Match')
        if client_etag and client_etag.strip() == etag:
            return request.make_response('', headers=[('ETag', etag)], status=304)

        return json_response(schema_data, headers={'ETag': etag})

    @http.route('/api/mobile/v1/meta/lookup/<string:field_name>', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth()
    def lookup_field(self, field_name, current_user, is_admin):
        # Verify field is exposed in mobile field config
        role = 'admin' if is_admin else 'customer'
        cfg = request.env['helpdesk.mobile.field.config'].sudo().search([
            ('name', '=', field_name),
            ('active', '=', True)
        ], limit=1)
        if not cfg or (not is_admin and cfg.visible_to == 'admin'):
            return error_response('NOT_FOUND', 'Field not found or not exposed', status=404)

        f = cfg.field_id
        if f.ttype not in ['many2one', 'many2many']:
            return error_response('INVALID_TYPE', 'Lookup only available for relational fields', status=400)

        target_model = f.relation
        q = request.httprequest.args.get('q', '').strip()
        page = int(request.httprequest.args.get('page', 1))
        page_size = int(request.httprequest.args.get('page_size', 20))
        offset = (page - 1) * page_size

        domain = []
        if q:
            domain.append(('display_name', 'ilike', q))

        records = request.env[target_model].search(domain, offset=offset, limit=page_size)
        total = request.env[target_model].search_count(domain)

        data = [{'id': r.id, 'name': r.display_name} for r in records]
        meta = {
            'page': page,
            'page_size': page_size,
            'total': total,
            'has_more': (offset + len(records)) < total,
        }
        return json_response(data, meta=meta)
