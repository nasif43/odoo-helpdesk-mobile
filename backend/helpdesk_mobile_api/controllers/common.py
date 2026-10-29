# -*- coding: utf-8 -*-
import json
import functools
from odoo import http
from odoo.http import request

def json_response(data=None, meta=None, status=200, headers=None):
    payload = {'ok': True}
    if data is not None:
        payload['data'] = data
    if meta is not None:
        payload['meta'] = meta
    response_headers = [
        ('Content-Type', 'application/json'),
        ('Access-Control-Allow-Origin', '*'),
        ('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS'),
        ('Access-Control-Allow-Headers', 'Authorization, Content-Type, Idempotency-Key, If-None-Match'),
    ]
    if headers:
        for k, v in headers.items():
            response_headers.append((k, str(v)))
    return request.make_response(
        json.dumps(payload, default=str),
        headers=response_headers,
        status=status
    )

def error_response(code, message, status=400, fields=None):
    error_obj = {
        'code': code,
        'message': message,
    }
    if fields:
        error_obj['fields'] = fields
    payload = {
        'ok': False,
        'error': error_obj
    }
    return request.make_response(
        json.dumps(payload),
        headers=[
            ('Content-Type', 'application/json'),
            ('Access-Control-Allow-Origin', '*'),
            ('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS'),
            ('Access-Control-Allow-Headers', 'Authorization, Content-Type, Idempotency-Key, If-None-Match'),
        ],
        status=status
    )

def get_json_body():
    try:
        raw = request.httprequest.data
        if not raw:
            return {}
        return json.loads(raw.decode('utf-8'))
    except Exception:
        return {}

def require_auth(role='any'):
    """
    Decorator for mobile endpoints.
    role: 'any' (authenticated customer or admin), 'admin' (manager only), 'customer' (portal only)
    """
    def decorator(fn):
        @functools.wraps(fn)
        def wrapper(*args, **kwargs):
            auth_header = request.httprequest.headers.get('Authorization', '')
            if not auth_header.startswith('Bearer '):
                return error_response('UNAUTHORIZED', 'Missing or invalid Authorization header', status=401)
            
            token_str = auth_header[7:].strip()
            token_model = request.env['helpdesk.mobile.token'].sudo()
            user = token_model.verify_token(token_str, expected_type='access')
            if not user:
                return error_response('TOKEN_EXPIRED', 'Access token is invalid or expired', status=401)

            is_admin = user.has_group('helpdesk.group_helpdesk_manager')
            if role == 'admin' and not is_admin:
                return error_response('FORBIDDEN', 'Administrator privileges required', status=403)
            if role == 'customer' and is_admin:
                pass  # Admin can optionally test customer endpoints if needed, but primarily for portal

            # Switch request.env context to authenticated user so ORM record rules apply
            request.update_env(user=user)
            kwargs['current_user'] = user
            kwargs['is_admin'] = is_admin
            return fn(*args, **kwargs)
        return wrapper
    return decorator

class CommonCorsController(http.Controller):
    @http.route('/api/mobile/v1/<path:subpath>', type='http', auth='none', methods=['OPTIONS'], csrf=False)
    def cors_options(self, subpath, **kwargs):
        return request.make_response('', headers=[
            ('Access-Control-Allow-Origin', '*'),
            ('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS'),
            ('Access-Control-Allow-Headers', 'Authorization, Content-Type, Idempotency-Key, If-None-Match'),
        ], status=200)
