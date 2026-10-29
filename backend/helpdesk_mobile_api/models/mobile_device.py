# -*- coding: utf-8 -*-
from odoo import models, fields, api

class MobileDevice(models.Model):
    _name = 'helpdesk.mobile.device'
    _description = 'Helpdesk Mobile Device Registration (FCM)'
    _order = 'write_date desc'

    user_id = fields.Many2one('res.users', string='User', required=True, ondelete='cascade', index=True)
    token = fields.Char(string='FCM Device Token', required=True, index=True)
    platform = fields.Selection([
        ('android', 'Android'),
        ('ios', 'iOS'),
        ('web', 'Web')
    ], string='Platform', default='android')
    app_version = fields.Char(string='App Version')
    last_seen = fields.Datetime(string='Last Seen', default=fields.Datetime.now)

    _unique_token = models.Constraint(
        'UNIQUE(token)',
        'Device token must be unique!'
    )

    @api.model
    def register_device(self, user, token, platform='android', app_version=None):
        if not token:
            return False
        existing = self.sudo().search([('token', '=', token)], limit=1)
        if existing:
            existing.write({
                'user_id': user.id,
                'platform': platform,
                'app_version': app_version,
                'last_seen': fields.Datetime.now()
            })
            return existing
        return self.sudo().create({
            'user_id': user.id,
            'token': token,
            'platform': platform,
            'app_version': app_version,
            'last_seen': fields.Datetime.now()
        })

    @api.model
    def unregister_device(self, token):
        existing = self.sudo().search([('token', '=', token)])
        if existing:
            existing.unlink()
        return True
