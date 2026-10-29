# -*- coding: utf-8 -*-
import base64
from odoo import http
from odoo.http import request
from .common import json_response, error_response, require_auth

class MobileAttachmentController(http.Controller):

    @http.route('/api/mobile/v1/attachments', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth()
    def upload_attachment(self, current_user, is_admin):
        files = request.httprequest.files.getlist('file')
        if not files and 'file' in request.httprequest.files:
            files = [request.httprequest.files['file']]
        if not files:
            return error_response('VALIDATION_ERROR', 'No file provided in multipart upload', status=400)

        uploaded = []
        max_size_mb = int(request.env['ir.config_parameter'].sudo().get_param('helpdesk_mobile.max_attachment_size_mb', 10))
        max_bytes = max_size_mb * 1024 * 1024

        for f in files:
            content = f.read()
            if len(content) > max_bytes:
                return error_response('FILE_TOO_LARGE', f'File exceeds {max_size_mb} MB limit', status=413)

            filename = f.filename or 'upload'
            mimetype = f.content_type or 'application/octet-stream'

            att = request.env['ir.attachment'].sudo().create({
                'name': filename,
                'datas': base64.b64encode(content),
                'mimetype': mimetype,
                'res_model': False,  # Staged; linked when ticket/message is posted
                'res_id': False,
            })
            uploaded.append({
                'id': att.id,
                'name': att.name,
                'mimetype': att.mimetype,
                'size': att.file_size,
            })

        if len(uploaded) == 1:
            return json_response(uploaded[0], status=201)
        return json_response(uploaded, status=201)

    @http.route('/api/mobile/v1/attachments/<int:attachment_id>', type='http', auth='public', methods=['GET'], csrf=False)
    @require_auth()
    def download_attachment(self, attachment_id, current_user, is_admin):
        att = request.env['ir.attachment'].sudo().browse(attachment_id)
        if not att.exists():
            return error_response('NOT_FOUND', 'Attachment not found', status=404)

        # Access check: if linked to a ticket, ensure customer owns that ticket
        if att.res_model == 'helpdesk.ticket' and att.res_id:
            ticket = request.env['helpdesk.ticket'].browse(att.res_id)
            if not is_admin and ticket.partner_id.id != current_user.partner_id.id:
                return error_response('FORBIDDEN', 'Access denied to this file', status=403)

        content = base64.b64decode(att.datas or '')
        return request.make_response(
            content,
            headers=[
                ('Content-Type', att.mimetype or 'application/octet-stream'),
                ('Content-Disposition', f'inline; filename="{att.name}"'),
                ('Content-Length', str(len(content))),
            ]
        )
