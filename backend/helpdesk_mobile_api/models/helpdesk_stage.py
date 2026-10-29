# -*- coding: utf-8 -*-
from odoo import models, fields, api

class HelpdeskStage(models.Model):
    _inherit = 'helpdesk.stage'

    is_close = fields.Boolean(
        string='Closing Stage',
        default=False,
        help='Whether tickets in this stage are considered resolved or closed.'
    )

    @api.model_create_multi
    def create(self, vals_list):
        for vals in vals_list:
            if 'is_close' not in vals and vals.get('name') in ['Done', 'Rejected', 'Solved', 'Cancelled']:
                vals['is_close'] = True
        return super().create(vals_list)
