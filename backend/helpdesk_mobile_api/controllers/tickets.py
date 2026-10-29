# -*- coding: utf-8 -*-
from datetime import datetime, timedelta
from odoo import http, fields
from odoo.http import request
from odoo.exceptions import AccessError
from .common import json_response, error_response, get_json_body, require_auth

class MobileTicketController(http.Controller):

    def _get_actor_name(self, current_user):
        emp = request.env['hr.employee'].sudo().search([('user_id', '=', current_user.id)], limit=1)
        if not emp and current_user.partner_id:
            emp = request.env['hr.employee'].sudo().search([('user_id.partner_id', '=', current_user.partner_id.id)], limit=1)
        if emp and emp.name:
            name = emp.name
        else:
            name = current_user.name or 'Staff'
        if name == 'Business Owner':
            name = 'Marcus Vance'
        return name

    # -------------------------------------------------------------------------
    # Ticket Listing & Creation
    # -------------------------------------------------------------------------
    @http.route('/api/mobile/v1/tickets', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth()
    def list_tickets(self, current_user, is_admin):
        args = request.httprequest.args
        page = int(args.get('page', 1))
        page_size = int(args.get('page_size', 20))
        offset = (page - 1) * page_size

        domain = []

        # Customer scoping is automatic via record rules in request.env,
        # but we also explicitly enforce partner_id check for security
        if not is_admin:
            domain.append(('partner_id', '=', current_user.partner_id.id))

        # Query filters
        q = args.get('q', '').strip()
        if q:
            if q.startswith('#') and q[1:].isdigit():
                domain.append(('id', '=', int(q[1:])))
            else:
                domain.append('|')
                domain.append(('name', 'ilike', q))
                domain.append(('partner_id.name', 'ilike', q))

        stage_id = args.get('stage_id')
        if stage_id and stage_id.isdigit():
            domain.append(('stage_id', '=', int(stage_id)))

        stage_group = args.get('stage_group', '').lower()
        if stage_group == 'open':
            domain.append(('stage_id.name', 'in', ['New', 'Approved']))
        elif stage_group in ['in_progress', 'progress']:
            domain.append(('stage_id.name', 'in', ['Tracking', 'Work In Progress', 'Solving']))
        elif stage_group == 'solving':
            domain.append(('stage_id.name', '=', 'Solving'))
        elif stage_group == 'tracking':
            domain.append(('stage_id.name', '=', 'Tracking'))
        elif stage_group == 'new':
            domain.append(('stage_id.name', '=', 'New'))
        elif stage_group == 'approved':
            domain.append(('stage_id.name', '=', 'Approved'))
        elif stage_group == 'done':
            domain.append(('stage_id.name', '=', 'Done'))
        elif stage_group == 'rejected':
            domain.append(('stage_id.name', '=', 'Rejected'))

        priority = args.get('priority')
        if priority is not None and priority != '':
            domain.append(('priority', '=', str(priority)))

        assignee_id = args.get('assignee_id')
        if assignee_id and is_admin:
            if assignee_id == 'unassigned':
                domain.append(('employee_id', '=', False))
                domain.append(('user_id', '=', False))
            elif assignee_id.isdigit():
                aid = int(assignee_id)
                domain.append('|')
                domain.append(('employee_id', '=', aid))
                domain.append(('user_id', '=', aid))

        customer_id = args.get('customer_id')
        if customer_id and is_admin and customer_id.isdigit():
            domain.append(('partner_id', '=', int(customer_id)))

        # Custom field filters: custom[field_name]=value
        for k, v in args.items():
            if k.startswith('custom[') and k.endswith(']'):
                fname = k[7:-1]
                # Verify filterable
                cfg = request.env['helpdesk.mobile.field.config'].sudo().search([
                    ('name', '=', fname),
                    ('filterable', '=', True),
                    ('active', '=', True)
                ], limit=1)
                if cfg:
                    domain.append((fname, '=', v))

        sort_by = args.get('sort', 'updated_desc')
        order_map = {
            'updated_desc': 'write_date desc',
            'created_desc': 'create_date desc',
            'priority_desc': 'priority desc, write_date desc',
        }
        order = order_map.get(sort_by, 'write_date desc')

        ticket_model = request.env['helpdesk.ticket']
        total = ticket_model.search_count(domain)
        tickets = ticket_model.search(domain, offset=offset, limit=page_size, order=order)

        ticket_list = [t.to_mobile_dict(current_user, detail=False) for t in tickets]
        meta = {
            'page': page,
            'page_size': page_size,
            'total': total,
            'has_more': (offset + len(tickets)) < total,
        }
        return json_response(ticket_list, meta=meta)

    @http.route('/api/mobile/v1/tickets', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth()
    def create_ticket(self, current_user, is_admin):
        # Idempotency check
        idempotency_key = request.httprequest.headers.get('Idempotency-Key')
        if idempotency_key:
            # Check if recently created with this key in token/cache
            recent = request.env['helpdesk.ticket'].sudo().search([
                ('name', 'ilike', f"[IDEM:{idempotency_key}]")
            ], limit=1)
            if recent:
                return json_response(recent.to_mobile_dict(current_user, detail=True), status=200)

        body = get_json_body()
        subject = body.get('subject', '').strip()
        description = body.get('description', '').strip()
        priority = str(body.get('priority', 0))
        tag_ids = body.get('tag_ids', [])
        attachment_ids = body.get('attachment_ids', [])
        custom_values = body.get('custom', {})

        errors = {}
        if not subject:
            errors['subject'] = 'Subject is required'
        if not description:
            errors['description'] = 'Description is required'

        # Validate required custom fields from schema
        role = 'admin' if is_admin else 'customer'
        field_configs = request.env['helpdesk.mobile.field.config'].sudo().search([
            ('active', '=', True)
        ])
        for cfg in field_configs:
            if not is_admin and cfg.visible_to == 'admin':
                continue
            if cfg.required_in_app or cfg.field_id.required:
                if cfg.name not in custom_values or custom_values[cfg.name] in [None, '', []]:
                    errors[cfg.name] = f"{cfg.field_description} is required"

        if errors:
            return error_response('VALIDATION_ERROR', 'Validation failed', status=422, fields=errors)

        # Team and stage
        team = request.env['helpdesk.team'].search([('name', '=', 'Customer Support')], limit=1)
        if not team:
            team = request.env['helpdesk.team'].search([], limit=1)

        stage_new = request.env['helpdesk.stage'].search([
            ('name', '=', 'New'),
            ('team_ids', 'in', [team.id])
        ], limit=1)
        if not stage_new:
            stage_new = team.stage_ids.sorted('sequence')[0]

        vals = {
            'name': subject,
            'description': f"<p>{description}</p>",
            'team_id': team.id,
            'stage_id': stage_new.id,
            'priority': priority,
            'partner_id': current_user.partner_id.id if not is_admin else body.get('customer_id', current_user.partner_id.id),
        }

        # Apply allowed custom fields
        for cfg in field_configs:
            if cfg.name in custom_values:
                # Customers can only write to fields where customer_editable is create or always
                if not is_admin and cfg.customer_editable == 'never':
                    continue
                vals[cfg.name] = custom_values[cfg.name]

        if tag_ids:
            vals['tag_ids'] = [(6, 0, tag_ids)]

        try:
            ticket = request.env['helpdesk.ticket'].sudo().create(vals)

            # Link attachments if passed
            if attachment_ids:
                request.env['ir.attachment'].sudo().browse(attachment_ids).write({
                    'res_model': 'helpdesk.ticket',
                    'res_id': ticket.id,
                })

            # Post initial message to chatter
            ticket.message_post(
                body=f"Ticket created via Mobile App by {self._get_actor_name(current_user)}",
                message_type='comment',
                subtype_xmlid='mail.mt_comment'
            )

            return json_response(ticket.to_mobile_dict(current_user, detail=True), status=201)
        except Exception as e:
            return error_response('CREATION_FAILED', str(e), status=500)

    # -------------------------------------------------------------------------
    # Ticket Detail, Messages & History
    # -------------------------------------------------------------------------
    @http.route('/api/mobile/v1/tickets/<int:ticket_id>', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth()
    def get_ticket_detail(self, ticket_id, current_user, is_admin):
        try:
            ticket = request.env['helpdesk.ticket'].browse(ticket_id)
            if not ticket.exists():
                return error_response('NOT_FOUND', 'Ticket not found', status=404)
            # Record rule check
            if not is_admin and ticket.partner_id.id != current_user.partner_id.id:
                return error_response('FORBIDDEN', 'Access denied to this ticket', status=403)
            return json_response(ticket.to_mobile_dict(current_user, detail=True))
        except AccessError:
            return error_response('FORBIDDEN', 'Access denied', status=403)

    @http.route('/api/mobile/v1/tickets/<int:ticket_id>/messages', type='http', auth='public', methods=['GET', 'POST'], csrf=False)
    @require_auth()
    def ticket_messages(self, ticket_id, current_user, is_admin):
        ticket = request.env['helpdesk.ticket'].browse(ticket_id)
        if not ticket.exists():
            return error_response('NOT_FOUND', 'Ticket not found', status=404)
        if not is_admin and ticket.partner_id.id != current_user.partner_id.id:
            return error_response('FORBIDDEN', 'Access denied', status=403)

        if request.httprequest.method == 'GET':
            domain = [
                ('model', '=', 'helpdesk.ticket'),
                ('res_id', '=', ticket.id),
                ('message_type', 'in', ['comment', 'notification'])
            ]
            # DATA LEAKAGE PREVENTION: Customers never see internal notes (subtype note)
            if not is_admin:
                note_subtype = request.env.ref('mail.mt_note', raise_if_not_found=False)
                if note_subtype:
                    domain.append(('subtype_id', '!=', note_subtype.id))

            messages = request.env['mail.message'].sudo().search(domain, order='date asc')
            msg_list = []
            for m in messages:
                is_internal = bool(m.subtype_id and m.subtype_id == request.env.ref('mail.mt_note', raise_if_not_found=False))

                body_raw = m.body or ''
                if isinstance(body_raw, str):
                    body_raw = body_raw.strip()
                else:
                    body_raw = str(body_raw).strip()

                # If body is empty or blank html tags, extract tracking values or skip
                if not body_raw or body_raw in ['<p></p>', '<p><br></p>', '<p>&nbsp;</p>']:
                    if m.tracking_value_ids:
                        changes = []
                        for tr in m.tracking_value_ids:
                            col_name = tr.field_id.field_description if tr.field_id else 'Field'
                            old_v = tr.old_value_char or (str(tr.old_value_integer) if tr.old_value_integer else '')
                            new_v = tr.new_value_char or (str(tr.new_value_integer) if tr.new_value_integer else '')
                            if old_v and new_v:
                                changes.append(f"{col_name}: {old_v} → {new_v}")
                            elif new_v:
                                changes.append(f"{col_name}: {new_v}")
                        if changes:
                            body_raw = f"<p>{', '.join(changes)}</p>"
                        else:
                            continue
                    else:
                        continue

                # Resolve human employee author name
                author_partner = m.author_id
                emp = request.env['hr.employee'].sudo().search([('user_id.partner_id', '=', author_partner.id)], limit=1)
                if not emp and author_partner.email:
                    emp = request.env['hr.employee'].sudo().search([('work_email', '=', author_partner.email)], limit=1)

                if emp and emp.name:
                    author_name = emp.name
                    job_title = emp.job_title or 'Helpdesk Specialist'
                else:
                    author_name = author_partner.name or 'Staff'
                    job_title = None

                if author_name == 'Business Owner':
                    author_name = 'Marcus Vance'
                    job_title = 'IT Operations Lead'

                msg_list.append({
                    'id': m.id,
                    'author': {
                        'id': m.author_id.id,
                        'name': author_name,
                        'job_title': job_title,
                    },
                    'body': body_raw,
                    'created_at': m.date.isoformat() if m.date else None,
                    'is_internal': is_internal,
                    'attachments': [{
                        'id': att.id,
                        'name': att.name,
                        'size': att.file_size,
                        'url': f"/api/mobile/v1/attachments/{att.id}"
                    } for att in m.attachment_ids]
                })
            return json_response(msg_list)

        elif request.httprequest.method == 'POST':
            # Check closed ticket reply restriction
            is_closed = bool(ticket.stage_id.is_close or ticket.stage_id.fold or (ticket.stage_id.name in ['Done', 'Rejected']))
            if not is_admin and is_closed:
                return error_response('TICKET_CLOSED', 'Replies are disabled on closed tickets. Reopen to continue.', status=400)

            body = get_json_body()
            message_body = body.get('body', '').strip()
            is_internal = bool(body.get('internal', False))
            attachment_ids = body.get('attachment_ids', [])

            if not message_body:
                return error_response('VALIDATION_ERROR', 'Message body is required', status=422)

            # Customer cannot post internal notes
            if not is_admin and is_internal:
                return error_response('FORBIDDEN', 'Customers cannot post internal notes', status=403)

            subtype = 'mail.mt_note' if is_internal else 'mail.mt_comment'
            msg = ticket.sudo().message_post(
                body=f"<p>{message_body}</p>",
                message_type='comment',
                subtype_xmlid=subtype,
                attachment_ids=attachment_ids,
                author_id=current_user.partner_id.id,
            )
            return json_response({
                'id': msg.id,
                'body': msg.body,
                'created_at': msg.date.isoformat() if msg.date else None,
                'is_internal': is_internal,
            }, status=201)

    @http.route('/api/mobile/v1/tickets/<int:ticket_id>/history', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth()
    def ticket_history(self, ticket_id, current_user, is_admin):
        ticket = request.env['helpdesk.ticket'].browse(ticket_id)
        if not ticket.exists():
            return error_response('NOT_FOUND', 'Ticket not found', status=404)
        if not is_admin and ticket.partner_id.id != current_user.partner_id.id:
            return error_response('FORBIDDEN', 'Access denied', status=403)

        # Track tracking values on mail.message for this ticket
        messages = request.env['mail.message'].sudo().search([
            ('model', '=', 'helpdesk.ticket'),
            ('res_id', '=', ticket.id),
            ('tracking_value_ids', '!=', False)
        ], order='date desc')

        history_items = []
        for m in messages:
            for tv in m.tracking_value_ids:
                field_name = tv.field_id.name if tv.field_id else ''
                # Customers only see stage changes; never assignment or internal fields
                if not is_admin and field_name != 'stage_id':
                    continue

                history_items.append({
                    'id': tv.id,
                    'field': field_name,
                    'field_label': tv.field_id.field_description if tv.field_id else 'Field',
                    'old_value': tv.old_value_char or str(tv.old_value_integer or ''),
                    'new_value': tv.new_value_char or str(tv.new_value_integer or ''),
                    'changed_by': m.author_id.name,
                    'changed_at': m.date.isoformat() if m.date else None,
                })
        return json_response(history_items)

    # -------------------------------------------------------------------------
    # Customer Actions: Confirm, Reopen, Rating
    # -------------------------------------------------------------------------
    @http.route('/api/mobile/v1/tickets/<int:ticket_id>/confirm', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth()
    def confirm_resolution(self, ticket_id, current_user, is_admin):
        ticket = request.env['helpdesk.ticket'].browse(ticket_id)
        if not ticket.exists():
            return error_response('NOT_FOUND', 'Ticket not found', status=404)
        if not is_admin and ticket.partner_id.id != current_user.partner_id.id:
            return error_response('FORBIDDEN', 'Access denied', status=403)

        stage_done = request.env['helpdesk.stage'].search([
            ('name', '=', 'Done'),
            ('team_ids', 'in', [ticket.team_id.id])
        ], limit=1)
        if not stage_done:
            stage_done = ticket.team_id.stage_ids.filtered(lambda s: s.fold or s.is_close)[:1]

        ticket.sudo().write({
            'stage_id': stage_done.id,
            'closed_by_partner': True,
        })
        ticket.sudo().message_post(
            body=f"Resolution confirmed by customer {self._get_actor_name(current_user)}. Ticket marked as Done.",
            subtype_xmlid='mail.mt_comment',
            author_id=current_user.partner_id.id,
        )
        return json_response(ticket.to_mobile_dict(current_user, detail=True))

    @http.route('/api/mobile/v1/tickets/<int:ticket_id>/reopen', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth()
    def reopen_ticket(self, ticket_id, current_user, is_admin):
        ticket = request.env['helpdesk.ticket'].browse(ticket_id)
        if not ticket.exists():
            return error_response('NOT_FOUND', 'Ticket not found', status=404)
        if not is_admin and ticket.partner_id.id != current_user.partner_id.id:
            return error_response('FORBIDDEN', 'Access denied', status=403)

        body = get_json_body()
        reason = body.get('reason', '').strip()
        if not reason:
            return error_response('VALIDATION_ERROR', 'Reason is required to reopen ticket', status=422)

        # Enforce reopen window (7 days)
        reopen_days = int(request.env['ir.config_parameter'].sudo().get_param('helpdesk_mobile.reopen_window_days', 7))
        if ticket.closed_at:
            elapsed = (fields.Datetime.now() - ticket.closed_at).days
            if elapsed > reopen_days:
                return error_response('WINDOW_EXPIRED', f'Reopening is only allowed within {reopen_days} days of closure', status=400)

        # Move back to Work In Progress
        stage_wip = request.env['helpdesk.stage'].search([
            ('name', '=', 'Work In Progress'),
            ('team_ids', 'in', [ticket.team_id.id])
        ], limit=1)
        if not stage_wip:
            stage_wip = ticket.team_id.stage_ids.filtered(lambda s: not s.fold and s.sequence > 1)[:1]

        ticket.sudo().write({
            'stage_id': stage_wip.id,
            'closed_at': False,
        })
        ticket.sudo().message_post(
            body=f"<strong>Ticket Reopened by customer:</strong> {reason}",
            subtype_xmlid='mail.mt_comment',
            author_id=current_user.partner_id.id,
        )
        return json_response(ticket.to_mobile_dict(current_user, detail=True))

    @http.route('/api/mobile/v1/tickets/<int:ticket_id>/rating', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth()
    def rate_ticket(self, ticket_id, current_user, is_admin):
        ticket = request.env['helpdesk.ticket'].browse(ticket_id)
        if not ticket.exists():
            return error_response('NOT_FOUND', 'Ticket not found', status=404)
        if not is_admin and ticket.partner_id.id != current_user.partner_id.id:
            return error_response('FORBIDDEN', 'Access denied', status=403)

        body = get_json_body()
        rating_val = int(body.get('rating', 5))
        comment = body.get('comment', '')

        # Post rating into chatter
        ticket.message_post(
            body=f"Customer satisfaction rating: {rating_val}/5 stars. Feedback: {comment}",
            subtype_xmlid='mail.mt_comment'
        )
        return json_response({'message': 'Rating submitted successfully'})

    # -------------------------------------------------------------------------
    # Admin Actions: Approve, Reject, Assign, Stage, Patch, Bulk, Dashboard
    # -------------------------------------------------------------------------
    @http.route('/api/mobile/v1/tickets/<int:ticket_id>/approve', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth(role='admin')
    def approve_ticket(self, ticket_id, current_user, is_admin):
        ticket = request.env['helpdesk.ticket'].browse(ticket_id)
        if not ticket.exists():
            return error_response('NOT_FOUND', 'Ticket not found', status=404)
        if ticket.stage_id.name != 'New':
            return error_response('INVALID_STATE', 'Only tickets in stage New can be approved', status=400)

        body = get_json_body()
        stage_approved = request.env['helpdesk.stage'].search([
            ('name', '=', 'Approved'),
            ('team_ids', 'in', [ticket.team_id.id])
        ], limit=1)

        vals = {'stage_id': stage_approved.id}
        if 'priority' in body:
            vals['priority'] = str(body['priority'])
        if 'assignee_id' in body and body['assignee_id']:
            vals['employee_id'] = int(body['assignee_id'])

        ticket.write(vals)

        comment = body.get('comment', '').strip()
        is_internal = bool(body.get('is_internal', False))
        subtype = 'mail.mt_note' if is_internal else 'mail.mt_comment'
        ticket.message_post(
            body=f"Ticket Approved by {self._get_actor_name(current_user)}." + (f" Note: {comment}" if comment else ""),
            subtype_xmlid=subtype
        )
        return json_response(ticket.to_mobile_dict(current_user, detail=True))

    @http.route('/api/mobile/v1/tickets/<int:ticket_id>/reject', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth(role='admin')
    def reject_ticket(self, ticket_id, current_user, is_admin):
        ticket = request.env['helpdesk.ticket'].browse(ticket_id)
        if not ticket.exists():
            return error_response('NOT_FOUND', 'Ticket not found', status=404)
        if ticket.stage_id.name != 'New':
            return error_response('INVALID_STATE', 'Only tickets in stage New can be rejected', status=400)

        body = get_json_body()
        reason = body.get('reason', '').strip()
        if not reason:
            return error_response('VALIDATION_ERROR', 'Rejection reason is required', status=422)

        stage_rejected = request.env['helpdesk.stage'].search([
            ('name', '=', 'Rejected'),
            ('team_ids', 'in', [ticket.team_id.id])
        ], limit=1)

        ticket.write({
            'stage_id': stage_rejected.id,
            'rejection_reason': reason,
            'closed_at': fields.Datetime.now()
        })
        # Customer-visible message explaining rejection
        ticket.message_post(
            body=f"<strong>Ticket Declined:</strong> {reason}",
            subtype_xmlid='mail.mt_comment'
        )
        return json_response(ticket.to_mobile_dict(current_user, detail=True))

    @http.route('/api/mobile/v1/tickets/<int:ticket_id>/assign', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth(role='admin')
    def assign_ticket(self, ticket_id, current_user, is_admin):
        ticket = request.env['helpdesk.ticket'].browse(ticket_id)
        if not ticket.exists():
            return error_response('NOT_FOUND', 'Ticket not found', status=404)

        body = get_json_body()
        assignee_id = body.get('assignee_id') or body.get('employee_id')
        employee_id = int(assignee_id) if assignee_id else False

        ticket.write({'employee_id': employee_id})
        assignee_name = ticket.employee_id.name if ticket.employee_id else (ticket.user_id.name if ticket.user_id else "Unassigned")
        ticket.message_post(
            body=f"Ticket assigned to {assignee_name} by {self._get_actor_name(current_user)}",
            subtype_xmlid='mail.mt_note'
        )
        return json_response(ticket.to_mobile_dict(current_user, detail=True))

    @http.route('/api/mobile/v1/tickets/<int:ticket_id>/stage', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth(role='admin')
    def change_stage(self, ticket_id, current_user, is_admin):
        ticket = request.env['helpdesk.ticket'].browse(ticket_id)
        if not ticket.exists():
            return error_response('NOT_FOUND', 'Ticket not found', status=404)

        body = get_json_body()
        stage_id = int(body.get('stage_id', 0))
        target_stage = request.env['helpdesk.stage'].browse(stage_id)
        if not target_stage.exists():
            return error_response('VALIDATION_ERROR', 'Target stage does not exist', status=422)

        comment = body.get('comment', '').strip()
        vals = {'stage_id': target_stage.id}
        if target_stage.fold or target_stage.is_close or (target_stage.name in ['Done', 'Rejected']):
            vals['closed_at'] = fields.Datetime.now()
        else:
            vals['closed_at'] = False
        ticket.write(vals)
        ticket.message_post(
            body=f"Stage changed to {target_stage.name} by {self._get_actor_name(current_user)}." + (f" Comment: {comment}" if comment else ""),
            subtype_xmlid='mail.mt_comment'
        )
        return json_response(ticket.to_mobile_dict(current_user, detail=True))

    @http.route('/api/mobile/v1/tickets/<int:ticket_id>', type='http', auth='public', methods=['PATCH'], csrf=False)
    @require_auth(role='admin')
    def patch_ticket(self, ticket_id, current_user, is_admin):
        ticket = request.env['helpdesk.ticket'].browse(ticket_id)
        if not ticket.exists():
            return error_response('NOT_FOUND', 'Ticket not found', status=404)

        body = get_json_body()
        vals = {}
        if 'priority' in body:
            vals['priority'] = str(body['priority'])
        if 'tag_ids' in body:
            vals['tag_ids'] = [(6, 0, body['tag_ids'])]

        # Custom fields updates
        custom_values = body.get('custom', {})
        for fname, val in custom_values.items():
            cfg = request.env['helpdesk.mobile.field.config'].sudo().search([
                ('name', '=', fname),
                ('admin_editable', '=', True),
                ('active', '=', True)
            ], limit=1)
            if cfg:
                vals[fname] = val

        if vals:
            ticket.write(vals)

        return json_response(ticket.to_mobile_dict(current_user, detail=True))

    @http.route('/api/mobile/v1/tickets/bulk', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth(role='admin')
    def bulk_actions(self, current_user, is_admin):
        body = get_json_body()
        ticket_ids = body.get('ids', [])
        action = body.get('action')
        params = body.get('params', {})

        if not ticket_ids or len(ticket_ids) > 50:
            return error_response('VALIDATION_ERROR', 'ids must contain 1 to 50 ticket IDs', status=422)

        results = []
        tickets = request.env['helpdesk.ticket'].browse(ticket_ids)
        for t in tickets:
            try:
                if action == 'approve':
                    if t.stage_id.name == 'New':
                        stage_app = request.env['helpdesk.stage'].search([('name', '=', 'Approved')], limit=1)
                        t.write({'stage_id': stage_app.id})
                        results.append({'id': t.id, 'ok': True})
                    else:
                        results.append({'id': t.id, 'ok': False, 'error': 'Not in stage New'})
                elif action == 'assign':
                    uid = params.get('assignee_id') or params.get('employee_id')
                    t.write({'employee_id': int(uid) if uid else False})
                    results.append({'id': t.id, 'ok': True})
                elif action == 'stage':
                    sid = int(params.get('stage_id', 0))
                    tgt = request.env['helpdesk.stage'].browse(sid)
                    vals = {'stage_id': sid}
                    if tgt.fold or tgt.is_close or (tgt.name in ['Done', 'Rejected']):
                        vals['closed_at'] = fields.Datetime.now()
                    else:
                        vals['closed_at'] = False
                    t.write(vals)
                    results.append({'id': t.id, 'ok': True})
                else:
                    results.append({'id': t.id, 'ok': False, 'error': f'Unknown action {action}'})
            except Exception as e:
                results.append({'id': t.id, 'ok': False, 'error': str(e)})

        return json_response({'results': results})

    @http.route('/api/mobile/v1/dashboard', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth(role='admin')
    def dashboard(self, current_user, is_admin):
        ticket_model = request.env['helpdesk.ticket']
        
        # Stage counts filtered to Customer Support team
        team = request.env['helpdesk.team'].sudo().search([('name', '=', 'Customer Support')], limit=1)
        if not team:
            team = request.env['helpdesk.team'].sudo().search([], limit=1)
        stages = team.stage_ids.sorted('sequence') if team else request.env['helpdesk.stage'].sudo().search([('active', '=', True)], order='sequence')
        stage_counts = []
        for s in stages:
            count = ticket_model.search_count([('stage_id', '=', s.id)])
            stage_counts.append({
                'id': s.id,
                'name': s.name,
                'count': count,
                'is_closed': bool(s.is_close or s.fold or (s.name in ['Done', 'Rejected']))
            })

        awaiting_approval = ticket_model.search_count([('stage_id.name', '=', 'New')])
        unassigned = ticket_model.search_count([
            ('employee_id', '=', False),
            ('user_id', '=', False),
            ('stage_id.fold', '=', False)
        ])
        urgent = ticket_model.search_count([('priority', '=', '3'), ('stage_id.fold', '=', False)])
        
        # Calculate tickets assigned to current user / employee
        current_emp = request.env['hr.employee'].sudo().search([('user_id', '=', current_user.id)], limit=1)
        if current_emp:
            mine = ticket_model.search_count([
                '|', ('employee_id', '=', current_emp.id), ('user_id', '=', current_user.id),
                ('stage_id.fold', '=', False)
            ])
        else:
            mine = ticket_model.search_count([('user_id', '=', current_user.id), ('stage_id.fold', '=', False)])

        # Recent activity
        recent = ticket_model.search([], limit=10, order='write_date desc')

        data = {
            'awaiting_approval': awaiting_approval,
            'unassigned': unassigned,
            'urgent': urgent,
            'mine': mine,
            'stages': stage_counts,
            'recent_tickets': [t.to_mobile_dict(current_user, detail=False) for t in recent]
        }
        return json_response(data)

    @http.route('/api/mobile/v1/customers', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth(role='admin')
    def get_customers(self, current_user, is_admin):
        args = request.httprequest.args
        page = int(args.get('page', 1))
        page_size = int(args.get('page_size', 20))
        offset = (page - 1) * page_size
        q = args.get('q', '').strip()

        domain = [('user_ids.share', '=', True)]
        if q:
            domain.append('|')
            domain.append(('name', 'ilike', q))
            domain.append(('email', 'ilike', q))

        partner_model = request.env['res.partner']
        total = partner_model.search_count(domain)
        partners = partner_model.search(domain, offset=offset, limit=page_size, order='name')

        results = []
        for p in partners:
            total_tickets = request.env['helpdesk.ticket'].search_count([('partner_id', '=', p.id)])
            open_tickets = request.env['helpdesk.ticket'].search_count([
                ('partner_id', '=', p.id),
                ('stage_id.fold', '=', False)
            ])
            results.append({
                'id': p.id,
                'name': p.name,
                'email': p.email or '',
                'phone': p.phone or '',
                'total_tickets': total_tickets,
                'open_tickets': open_tickets,
            })

        meta = {
            'page': page,
            'page_size': page_size,
            'total': total,
            'has_more': (offset + len(partners)) < total,
        }
        return json_response(results, meta=meta)
