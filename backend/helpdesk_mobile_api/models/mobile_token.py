# -*- coding: utf-8 -*-
import secrets
from datetime import datetime, timedelta
from odoo import models, fields, api
from odoo.exceptions import AccessDenied

class MobileToken(models.Model):
    _name = 'helpdesk.mobile.token'
    _description = 'Helpdesk Mobile Authentication Token'
    _order = 'create_date desc'

    token = fields.Char(string='Token', required=True, index=True)
    user_id = fields.Many2one('res.users', string='User', required=True, ondelete='cascade', index=True)
    token_type = fields.Selection([
        ('access', 'Access Token'),
        ('refresh', 'Refresh Token')
    ], string='Token Type', required=True, default='access')
    expires_at = fields.Datetime(string='Expires At', required=True, index=True)
    revoked = fields.Boolean(string='Revoked', default=False, index=True)
    platform = fields.Char(string='Platform')
    app_version = fields.Char(string='App Version')

    @api.model
    def create_token_pair(self, user, platform=None, app_version=None):
        now = fields.Datetime.now()
        # Access token: 60 minutes
        access_expires = now + timedelta(minutes=60)
        # Refresh token: 30 days
        refresh_expires = now + timedelta(days=30)

        access_token_str = secrets.token_urlsafe(48)
        refresh_token_str = secrets.token_urlsafe(64)

        self.create({
            'token': access_token_str,
            'user_id': user.id,
            'token_type': 'access',
            'expires_at': access_expires,
            'platform': platform,
            'app_version': app_version,
        })

        self.create({
            'token': refresh_token_str,
            'user_id': user.id,
            'token_type': 'refresh',
            'expires_at': refresh_expires,
            'platform': platform,
            'app_version': app_version,
        })

        role = 'admin' if user.has_group('helpdesk.group_helpdesk_manager') else 'customer'
        emp = self.env['hr.employee'].sudo().search([('user_id', '=', user.id)], limit=1)
        name = emp.name if emp and emp.name else user.name
        if name == 'Business Owner':
            name = 'Marcus Vance'

        return {
            'access_token': access_token_str,
            'refresh_token': refresh_token_str,
            'expires_in': 3600,
            'user': {
                'id': user.id,
                'employee_id': emp.id if emp else None,
                'name': name,
                'email': user.email or user.login,
                'role': role,
                'partner_id': user.partner_id.id,
            }
        }

    @api.model
    def verify_token(self, token_str, expected_type='access'):
        if not token_str:
            return False
        now = fields.Datetime.now()
        token_record = self.sudo().search([
            ('token', '=', token_str),
            ('token_type', '=', expected_type),
            ('revoked', '=', False),
            ('expires_at', '>', now)
        ], limit=1)
        if not token_record:
            return False
        return token_record.user_id

    @api.model
    def rotate_refresh_token(self, refresh_token_str):
        now = fields.Datetime.now()
        token_record = self.sudo().search([
            ('token', '=', refresh_token_str),
            ('token_type', '=', 'refresh'),
            ('revoked', '=', False),
            ('expires_at', '>', now)
        ], limit=1)
        if not token_record:
            raise AccessDenied("Invalid or expired refresh token")
        
        # Revoke old refresh token
        token_record.revoked = True
        user = token_record.user_id
        return self.create_token_pair(user, platform=token_record.platform, app_version=token_record.app_version)

    @api.model
    def revoke_token(self, token_str):
        records = self.sudo().search([('token', '=', token_str)])
        if records:
            records.write({'revoked': True})
        return True
