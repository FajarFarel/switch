from functools import wraps

from flask import request, jsonify, g

from app.utils.security import decode_token


def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):

        auth_header = request.headers.get("Authorization")

        if not auth_header:
            return jsonify({
                "success": False,
                "message": "Authorization header diperlukan"
            }), 401

        if not auth_header.startswith("Bearer "):
            return jsonify({
                "success": False,
                "message": "Format Authorization tidak valid"
            }), 401

        token = auth_header.split(" ", 1)[1]

        payload = decode_token(token)

        if not payload:
            return jsonify({
                "success": False,
                "message": "Token tidak valid atau sudah expired"
            }), 401

        g.user_id = payload["user_id"]

        return f(*args, **kwargs)

    return decorated