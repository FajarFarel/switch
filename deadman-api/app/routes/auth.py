from flask import Blueprint, request, jsonify, g
from app.utils.auth import token_required
from app.db import get_db_connection
from app.utils.security import (
    hash_password,
    verify_password,
    create_token
)


auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}

    username = data.get("username")
    email = data.get("email")
    password = data.get("password")

    if not username or not email or not password:
        return jsonify({
            "success": False,
            "message": "username, email, dan password wajib diisi"
        }), 400

    if len(password) < 8:
        return jsonify({
            "success": False,
            "message": "password minimal 8 karakter"
        }), 400

    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute(
                """
                SELECT id
                FROM users
                WHERE username = %s OR email = %s
                LIMIT 1
                """,
                (username, email)
            )

            existing_user = cursor.fetchone()

            if existing_user:
                return jsonify({
                    "success": False,
                    "message": "username atau email sudah digunakan"
                }), 409

            password_hash = hash_password(password)

            cursor.execute(
                """
                INSERT INTO users
                (username, email, password_hash)
                VALUES (%s, %s, %s)
                """,
                (username, email, password_hash)
            )

            user_id = cursor.lastrowid

            connection.commit()

            return jsonify({
                "success": True,
                "message": "registrasi berhasil",
                "data": {
                    "id": user_id,
                    "username": username,
                    "email": email
                }
            }), 201

    except Exception as e:
        connection.rollback()

        return jsonify({
            "success": False,
            "message": "terjadi kesalahan server",
            "error": str(e)
        }), 500

    finally:
        connection.close()


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}

    email = data.get("email")
    password = data.get("password")

    if not email or not password:
        return jsonify({
            "success": False,
            "message": "email dan password wajib diisi"
        }), 400

    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute(
                """
                SELECT
                    id,
                    username,
                    email,
                    password_hash,
                    is_active
                FROM users
                WHERE email = %s
                LIMIT 1
                """,
                (email,)
            )

            user = cursor.fetchone()

            if not user:
                return jsonify({
                    "success": False,
                    "message": "email atau password salah"
                }), 401

            if not user["is_active"]:
                return jsonify({
                    "success": False,
                    "message": "akun tidak aktif"
                }), 403

            if not verify_password(
                password,
                user["password_hash"]
            ):
                return jsonify({
                    "success": False,
                    "message": "email atau password salah"
                }), 401

            token = create_token(user["id"])

            return jsonify({
                "success": True,
                "message": "login berhasil",
                "data": {
                    "token": token,
                    "user": {
                        "id": user["id"],
                        "username": user["username"],
                        "email": user["email"]
                    }
                }
            }), 200

    finally:
        connection.close()

@auth_bp.route("/me", methods=["GET"])
@token_required
def me():

    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute(
                """
                SELECT
                    id,
                    username,
                    email,
                    is_active,
                    created_at
                FROM users
                WHERE id = %s
                LIMIT 1
                """,
                (g.user_id,)
            )

            user = cursor.fetchone()

            if not user:
                return jsonify({
                    "success": False,
                    "message": "User tidak ditemukan"
                }), 404

            return jsonify({
                "success": True,
                "data": {
                    "id": user["id"],
                    "username": user["username"],
                    "email": user["email"],
                    "is_active": user["is_active"],
                    "created_at": user["created_at"]
                }
            }), 200

    finally:
        connection.close()