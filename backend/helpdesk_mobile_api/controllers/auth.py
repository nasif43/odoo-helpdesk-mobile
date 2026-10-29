# -*- coding: utf-8 -*-
from odoo import http
from odoo.http import request
from odoo.exceptions import AccessDenied
from .common import json_response, error_response, get_json_body, require_auth

class MobileAuthController(http.Controller):

    @http.route('/api/mobile/v1/auth/login', type='http', auth='public', methods=['POST'], csrf=False)
    def login(self):
        body = get_json_body()
        email = body.get('email', '').strip()
        password = body.get('password', '')
        platform = body.get('platform')
        app_version = body.get('app_version')

        if not email or not password:
            return error_response('INVALID_CREDENTIALS', 'Email and password are required', status=400)

        db = request.env.cr.dbname
        try:
            # Authenticate via Odoo 19 credential dictionary
            credential = {'login': email, 'password': password, 'type': 'password'}
            auth_res = request.env['res.users'].sudo().authenticate(credential, None)
            uid = auth_res.get('uid') if isinstance(auth_res, dict) else auth_res
            if not uid:
                return error_response('INVALID_CREDENTIALS', 'Invalid email or password', status=401)
            
            user = request.env['res.users'].sudo().browse(uid)
            token_model = request.env['helpdesk.mobile.token'].sudo()
            token_data = token_model.create_token_pair(user, platform=platform, app_version=app_version)
            return json_response(token_data)
        except AccessDenied:
            return error_response('INVALID_CREDENTIALS', 'Invalid email or password', status=401)
        except Exception as e:
            return error_response('SERVER_ERROR', str(e), status=500)

    @http.route('/api/mobile/v1/auth/register', type='http', auth='public', methods=['POST'], csrf=False)
    def register(self):
        body = get_json_body()
        name = body.get('name', '').strip()
        email = body.get('email', '').strip().lower()
        password = body.get('password', '')
        phone = body.get('phone', '').strip()

        errors = {}
        if not name:
            errors['name'] = 'Full name is required'
        if not email:
            errors['email'] = 'Email is required'
        if not password or len(password) < 6:
            errors['password'] = 'Password must be at least 6 characters'
        if errors:
            return error_response('VALIDATION_ERROR', 'Input validation failed', status=422, fields=errors)

        # Check existing user
        existing = request.env['res.users'].sudo().search([('login', '=', email)], limit=1)
        if existing:
            return error_response('EMAIL_EXISTS', 'An account with this email already exists', status=409)

        try:
            group_portal = request.env.ref('base.group_portal')
            partner = request.env['res.partner'].sudo().create({
                'name': name,
                'email': email,
                'phone': phone,
                'is_company': False,
            })
            user = request.env['res.users'].sudo().create({
                'name': name,
                'login': email,
                'partner_id': partner.id,
                'group_ids': [(6, 0, [group_portal.id])],
            })
            user.sudo().password = password

            token_model = request.env['helpdesk.mobile.token'].sudo()
            token_data = token_model.create_token_pair(user)
            return json_response(token_data, status=201)
        except Exception as e:
            return error_response('REGISTRATION_FAILED', str(e), status=500)

    @http.route('/api/mobile/v1/auth/refresh', type='http', auth='public', methods=['POST'], csrf=False)
    def refresh(self):
        body = get_json_body()
        refresh_token = body.get('refresh_token')
        if not refresh_token:
            return error_response('INVALID_TOKEN', 'refresh_token is required', status=400)
        
        try:
            token_model = request.env['helpdesk.mobile.token'].sudo()
            new_tokens = token_model.rotate_refresh_token(refresh_token)
            return json_response(new_tokens)
        except AccessDenied as e:
            return error_response('TOKEN_EXPIRED', str(e), status=401)
        except Exception as e:
            return error_response('SERVER_ERROR', str(e), status=500)

    @http.route('/api/mobile/v1/auth/logout', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth()
    def logout(self, current_user, is_admin):
        body = get_json_body()
        refresh_token = body.get('refresh_token')
        auth_header = request.httprequest.headers.get('Authorization', '')
        access_token = auth_header[7:].strip() if auth_header.startswith('Bearer ') else None

        token_model = request.env['helpdesk.mobile.token'].sudo()
        if access_token:
            token_model.revoke_token(access_token)
        if refresh_token:
            token_model.revoke_token(refresh_token)

        # Unregister push token if passed
        device_token = body.get('device_token')
        if device_token:
            request.env['helpdesk.mobile.device'].sudo().unregister_device(device_token)

        return json_response({'message': 'Logged out successfully'})

    @http.route('/api/mobile/v1/auth/forgot-password', type='http', auth='public', methods=['POST'], csrf=False)
    def forgot_password(self):
        body = get_json_body()
        email = body.get('email', '').strip().lower()
        if not email:
            return error_response('INVALID_REQUEST', 'Email is required', status=400)

        user = request.env['res.users'].sudo().search([('login', '=', email)], limit=1)
        if user:
            try:
                user.sudo().action_reset_password()
            except Exception:
                pass  # Do not leak failure to prevent user enumeration
        return json_response({'message': 'If the email exists, a password reset link has been dispatched'})

    @http.route('/api/mobile/v1/auth/change-password', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth()
    def change_password(self, current_user, is_admin):
        body = get_json_body()
        old_password = body.get('old_password')
        new_password = body.get('new_password')
        if not old_password or not new_password or len(new_password) < 6:
            return error_response('VALIDATION_ERROR', 'New password must be at least 6 characters', status=422)

        db = request.env.cr.dbname
        try:
            credential = {'login': current_user.login, 'password': old_password, 'type': 'password'}
            auth_res = request.env['res.users'].sudo().authenticate(credential, None)
            uid = auth_res.get('uid') if isinstance(auth_res, dict) else auth_res
            if not uid:
                return error_response('INVALID_PASSWORD', 'Current password is incorrect', status=400)
            current_user.sudo().password = new_password
            return json_response({'message': 'Password changed successfully'})
        except Exception as e:
            return error_response('SERVER_ERROR', str(e), status=500)

    @http.route('/api/mobile/v1/me', type='http', auth='public', methods=['GET', 'PATCH'], csrf=False)
    @require_auth()
    def me(self, current_user, is_admin):
        if request.httprequest.method == 'PATCH':
            body = get_json_body()
            vals = {}
            if 'name' in body and body['name'].strip():
                vals['name'] = body['name'].strip()
            if 'language' in body:
                vals['lang'] = body['language']
            if vals:
                current_user.sudo().write(vals)
            if 'phone' in body and current_user.partner_id:
                current_user.partner_id.sudo().write({'phone': body['phone'].strip()})

        role = 'admin' if is_admin else 'customer'
        emp = request.env['hr.employee'].sudo().search([('user_id', '=', current_user.id)], limit=1)
        name = emp.name if emp and emp.name else current_user.name
        if name == 'Business Owner':
            name = 'Marcus Vance'

        data = {
            'id': current_user.id,
            'employee_id': emp.id if emp else None,
            'name': name,
            'email': current_user.email or current_user.login,
            'phone': current_user.partner_id.phone or '',
            'role': role,
            'partner_id': current_user.partner_id.id,
            'language': current_user.lang or 'en_US',
        }
        return json_response(data)

    @http.route('/api/mobile/v1/me/devices', type='http', auth='public', methods=['POST'], csrf=False)
    @require_auth()
    def register_device(self, current_user, is_admin):
        body = get_json_body()
        token = body.get('token')
        platform = body.get('platform', 'android')
        app_version = body.get('app_version')
        if not token:
            return error_response('VALIDATION_ERROR', 'token is required', status=400)

        device = request.env['helpdesk.mobile.device'].sudo().register_device(
            current_user, token, platform=platform, app_version=app_version
        )
        return json_response({
            'registered': True,
            'token': device.token,
            'platform': device.platform,
        })

    @http.route('/api/mobile/v1/me/devices/<string:token>', type='http', auth='public', methods=['DELETE'], csrf=False)
    @require_auth()
    def unregister_device(self, token, current_user, is_admin):
        request.env['helpdesk.mobile.device'].sudo().unregister_device(token)
        return json_response({'unregistered': True})
