# -*- coding: utf-8 -*-
{
    'name': 'Helpdesk Mobile API',
    'version': '19.0.1.0.0',
    'category': 'Services/Helpdesk',
    'summary': 'REST API backend for Odoo Helpdesk Flutter Mobile Application',
    'description': """
        Exposes REST endpoints under /api/mobile/v1/ for:
        - Customer portal user authentication & registration
        - Admin login & executive dashboard
        - Complete ticket lifecycle: create, approve, reject, assign, track, solve, done, reopen
        - Dynamic schema-driven custom fields on helpdesk.ticket
        - Chatter messaging (public vs internal notes)
        - Push notification tokens and audit history
    """,
    'author': 'Antigravity / Metamorphosis',
    'depends': [
        'base',
        'helpdesk',
        'hr',
        'portal',
        'mail',
        'auth_signup',
    ],
    'data': [
        'security/ir.model.access.csv',
        'data/default_data.xml',
    ],
    'installable': True,
    'application': False,
    'auto_install': False,
    'license': 'LGPL-3',
}
