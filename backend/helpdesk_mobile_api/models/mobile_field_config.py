# -*- coding: utf-8 -*-
from odoo import models, fields, api

class MobileFieldConfig(models.Model):
    _name = 'helpdesk.mobile.field.config'
    _description = 'Helpdesk Mobile App Dynamic Field Configuration'
    _order = 'sequence, id'

    field_id = fields.Many2one(
        'ir.model.fields',
        string='Field',
        required=True,
        ondelete='cascade',
        domain="[('model', '=', 'helpdesk.ticket'), ('name', '=like', 'x_%')]"
    )
    name = fields.Char(related='field_id.name', string='Technical Name', store=True, readonly=True)
    field_description = fields.Char(related='field_id.field_description', string='Field Label', readonly=True)
    ttype = fields.Selection(related='field_id.ttype', string='Field Type', readonly=True)
    section_label = fields.Char(string='Section Label', default='Additional Information')
    sequence = fields.Integer(string='Display Sequence', default=10)
    
    show_on_create = fields.Boolean(string='Show on Create Form', default=True)
    show_on_detail = fields.Boolean(string='Show on Detail View', default=True)
    show_in_list = fields.Boolean(string='Show in List Card', default=False)
    filterable = fields.Boolean(string='Filterable in Admin List', default=False)
    
    visible_to = fields.Selection([
        ('both', 'Both Customer & Admin'),
        ('customer', 'Customer Only'),
        ('admin', 'Admin Only'),
    ], string='Visible To', default='both', required=True)
    
    customer_editable = fields.Selection([
        ('never', 'Never'),
        ('create', 'On Create Only'),
        ('always', 'Always while Open'),
    ], string='Customer Editable', default='create', required=True)
    
    admin_editable = fields.Boolean(string='Admin Editable', default=True)
    required_in_app = fields.Boolean(string='Required in App', default=False)
    active = fields.Boolean(string='Active', default=True)

    @api.model
    def get_schema_for_role(self, role='customer', lang=None):
        domain = [('active', '=', True)]
        if role == 'customer':
            domain.append(('visible_to', 'in', ['both', 'customer']))
        else:
            domain.append(('visible_to', 'in', ['both', 'admin']))

        configs = self.search(domain, order='sequence, id')
        fields_schema = []
        for cfg in configs:
            f = cfg.field_id
            if not f.exists():
                continue
            
            # Skip unsupported types safely as specified in Section 14.3
            supported_types = [
                'char', 'text', 'html', 'integer', 'float',
                'monetary', 'boolean', 'date', 'datetime',
                'selection', 'many2one', 'many2many'
            ]
            if f.ttype not in supported_types:
                continue

            entry = {
                'name': f.name,
                'label': f.field_description,
                'type': f.ttype,
                'section': cfg.section_label or 'Additional Information',
                'sequence': cfg.sequence,
                'required': cfg.required_in_app or f.required,
                'help': f.help or '',
                'show': {
                    'create': cfg.show_on_create,
                    'detail': cfg.show_on_detail,
                    'list': cfg.show_in_list,
                },
                'editable': {
                    'customer': cfg.customer_editable,
                    'admin': cfg.admin_editable,
                },
                'filterable': cfg.filterable,
            }

            if f.ttype == 'selection':
                selection_vals = []
                # Odoo selection values from ir.model.fields.selection
                if hasattr(f, 'selection_ids') and f.selection_ids:
                    for s in f.selection_ids:
                        selection_vals.append({'value': s.value, 'label': s.name})
                entry['options'] = selection_vals

            elif f.ttype in ['many2one', 'many2many']:
                entry['relation'] = {
                    'model': f.relation,
                    'lookup': f'/api/mobile/v1/meta/lookup/{f.name}'
                }

            elif f.ttype == 'monetary':
                entry['currency'] = {'symbol': '$', 'position': 'before'}

            fields_schema.append(entry)

        # Compute hash/version for schema
        import hashlib
        import json
        schema_json = json.dumps(fields_schema, sort_keys=True)
        version = hashlib.sha1(schema_json.encode('utf-8')).hexdigest()[:8]

        return {
            'version': version,
            'fields': fields_schema
        }
