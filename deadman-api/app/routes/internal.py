import os

from flask import Blueprint, request, jsonify
from app.config import Config
from app.services.email_service import send_test_email
from app.services.deadline_service import process_deadlines
from app.services.trigger_service import (
    process_triggers,
    recover_stuck_deliveries
)

internal_bp = Blueprint("internal", __name__)


@internal_bp.route("/deadline-check", methods=["POST"])
def deadline_check():

    cron_secret = Config.CRON_SECRET
    provided_secret = request.headers.get("X-Cron-Secret")

    if not cron_secret:
        return jsonify({
            "success": False,
            "message": "CRON_SECRET belum dikonfigurasi"
        }), 500

    if provided_secret != cron_secret:
        return jsonify({
            "success": False,
            "message": "Unauthorized"
        }), 401

    try:

        # 1. Process deadline
        deadline_result = process_deadlines()

        # 2. Recovery delivery yang nyangkut
        recovered = recover_stuck_deliveries()

        # 3. Process trigger
        trigger_result = process_triggers()

        return jsonify({
            "success": True,
            "message": "Deadline dan trigger processing selesai",
            "data": {
                "deadline": deadline_result,
                "trigger": trigger_result,
                "recovered_deliveries": recovered
            }
        }), 200

    except Exception as e:

        return jsonify({
            "success": False,
            "message": "Processing gagal",
            "error": str(e)
        }), 500

@internal_bp.route("/test-email", methods=["POST"])
def test_email():

    cron_secret = Config.CRON_SECRET

    provided_secret = request.headers.get(
        "X-Cron-Secret"
    )

    if not cron_secret or provided_secret != cron_secret:
        return jsonify({
            "success": False,
            "message": "Unauthorized"
        }), 401

    data = request.get_json(silent=True) or {}

    to_email = data.get("to")

    if not to_email:
        return jsonify({
            "success": False,
            "message": "to wajib diisi"
        }), 400

    try:
        response = send_test_email(to_email)

        return jsonify({
            "success": True,
            "message": "Email berhasil dikirim",
            "data": response
        }), 200

    except Exception as e:
        return jsonify({
            "success": False,
            "message": "Gagal mengirim email",
            "error": str(e)
        }), 500