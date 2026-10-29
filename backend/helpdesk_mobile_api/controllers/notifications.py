# -*- coding: utf-8 -*-
import re
import html
from odoo import http, fields
from odoo.http import request
from .common import json_response, error_response, require_auth

class MobileNotificationController(http.Controller):

    @http.route('/api/mobile/v1/notifications', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth()
    def list_notifications(self, current_user, is_admin):
        # Fetch notifications related to user's tickets
        domain = [('model', '=', 'helpdesk.ticket')]
        if not is_admin:
            domain.append(('author_id', '!=', current_user.partner_id.id))
            note_subtype = request.env.ref('mail.mt_note', raise_if_not_found=False)
            if note_subtype:
                domain.append(('subtype_id', '!=', note_subtype.id))
            # Tickets owned by customer
            cust_tickets = request.env['helpdesk.ticket'].search([('partner_id', '=', current_user.partner_id.id)])
            domain.append(('res_id', 'in', cust_tickets.ids))

        messages = request.env['mail.message'].sudo().search(domain, limit=30, order='date desc')
        notifications = []
        for m in messages:
            ticket = request.env['helpdesk.ticket'].sudo().browse(m.res_id)
            if not ticket.exists():
                continue

            body_clean = m.body or ''
            if body_clean:
                body_clean = re.sub(r'<[^>]*>', ' ', body_clean)
                body_clean = html.unescape(body_clean)
                body_clean = re.sub(r'\s+', ' ', body_clean).strip()
            if not body_clean:
                body_clean = 'New activity on your ticket'

            notifications.append({
                'id': m.id,
                'title': f"Update on #{ticket.id}: {ticket.name}",
                'body': body_clean,
                'ticket_id': ticket.id,
                'type': 'message',
                'is_read': False,
                'created_at': m.date.isoformat() if m.date else None,
            })

        return json_response(notifications, meta={'total': len(notifications)})

    @http.route('/api/mobile/v1/notifications/<int:notification_id>/read', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth()
    def mark_read(self, notification_id, current_user, is_admin):
        return json_response({'marked_read': True, 'id': notification_id})

    @http.route('/api/mobile/v1/notifications/read-all', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth()
    def mark_all_read(self, current_user, is_admin):
        return json_response({'marked_all_read': True})
