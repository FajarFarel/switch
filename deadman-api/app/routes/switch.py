from flask import Blueprint, request, jsonify, g

from app.utils.auth import token_required

from app.services.switch_service import (
    create_switch,
    get_user_switches,
    get_switch_by_id,
    update_switch,
    delete_switch,
    arm_switch,
    disarm_switch,
    checkin_switch
)

from app.db import get_db_connection


switch_bp = Blueprint("switch", __name__)


@switch_bp.route("", methods=["POST"])
@token_required
def create():

    data = request.get_json(silent=True) or {}

    name = data.get("name")
    checkin_interval = data.get("checkin_interval")
    grace_period = data.get("grace_period")

    if not name:
        return jsonify({
            "success": False,
            "message": "name wajib diisi"
        }), 400

    if checkin_interval is None:
        return jsonify({
            "success": False,
            "message": "checkin_interval wajib diisi"
        }), 400

    if grace_period is None:
        return jsonify({
            "success": False,
            "message": "grace_period wajib diisi"
        }), 400

    try:
        checkin_interval = int(checkin_interval)
        grace_period = int(grace_period)
    except (TypeError, ValueError):
        return jsonify({
            "success": False,
            "message": "interval harus berupa angka"
        }), 400

    if checkin_interval <= 0:
        return jsonify({
            "success": False,
            "message": "checkin_interval harus lebih dari 0"
        }), 400

    if grace_period <= 0:
        return jsonify({
            "success": False,
            "message": "grace_period harus lebih dari 0"
        }), 400

    switch_id = create_switch(
        g.user_id,
        name,
        checkin_interval,
        grace_period
    )

    return jsonify({
        "success": True,
        "message": "switch berhasil dibuat",
        "data": {
            "id": switch_id
        }
    }), 201


@switch_bp.route("", methods=["GET"])
@token_required
def get_all():

    switches = get_user_switches(g.user_id)

    return jsonify({
        "success": True,
        "data": switches
    }), 200


@switch_bp.route("/<int:switch_id>", methods=["GET"])
@token_required
def get_one(switch_id):

    switch = get_switch_by_id(
        switch_id,
        g.user_id
    )

    if not switch:
        return jsonify({
            "success": False,
            "message": "Switch tidak ditemukan"
        }), 404

    return jsonify({
        "success": True,
        "data": switch
    }), 200


@switch_bp.route("/<int:switch_id>", methods=["PUT"])
@token_required
def update(switch_id):

    data = request.get_json(silent=True) or {}

    name = data.get("name")
    checkin_interval = data.get("checkin_interval")
    grace_period = data.get("grace_period")

    if not name or checkin_interval is None or grace_period is None:
        return jsonify({
            "success": False,
            "message": "name, checkin_interval, dan grace_period wajib diisi"
        }), 400

    try:
        checkin_interval = int(checkin_interval)
        grace_period = int(grace_period)
    except (TypeError, ValueError):
        return jsonify({
            "success": False,
            "message": "interval harus berupa angka"
        }), 400

    if checkin_interval <= 0 or grace_period <= 0:
        return jsonify({
            "success": False,
            "message": "interval harus lebih dari 0"
        }), 400

    updated = update_switch(
        switch_id,
        g.user_id,
        name,
        checkin_interval,
        grace_period
    )

    if not updated:
        return jsonify({
            "success": False,
            "message": "Switch tidak ditemukan atau sedang aktif"
        }), 404

    return jsonify({
        "success": True,
        "message": "switch berhasil diupdate"
    }), 200


@switch_bp.route("/<int:switch_id>", methods=["DELETE"])
@token_required
def delete(switch_id):

    deleted = delete_switch(
        switch_id,
        g.user_id
    )

    if not deleted:
        return jsonify({
            "success": False,
            "message": "Switch tidak ditemukan atau sedang aktif"
        }), 404

    return jsonify({
        "success": True,
        "message": "switch berhasil dihapus"
    }), 200


@switch_bp.route("/<int:switch_id>/arm", methods=["POST"])
@token_required
def arm(switch_id):

    result, error = arm_switch(
        switch_id,
        g.user_id
    )

    if error:
        return jsonify({
            "success": False,
            "message": error
        }), 404

    return jsonify({
        "success": True,
        "message": "switch berhasil diaktifkan",
        "data": result
    }), 200


@switch_bp.route("/<int:switch_id>/disarm", methods=["POST"])
@token_required
def disarm(switch_id):

    updated = disarm_switch(
        switch_id,
        g.user_id
    )

    if not updated:
        return jsonify({
            "success": False,
            "message": "Switch tidak ditemukan atau tidak sedang aktif"
        }), 404

    return jsonify({
        "success": True,
        "message": "switch berhasil dimatikan"
    }), 200

@switch_bp.route("/<int:switch_id>/checkin", methods=["POST"])
@token_required
def checkin(switch_id):

    data = request.get_json(silent=True) or {}

    device_id = data.get("device_id")

    result, error = checkin_switch(              
        switch_id=switch_id,
        user_id=g.user_id,
        source="MOBILE",
        ip_address=request.remote_addr,
        device_id=device_id
    )

    if error:
        return jsonify({
            "success": False,
            "message": error
        }), 404

    return jsonify({
        "success": True,
        "message": "Check-in berhasil",
        "data": result
    }), 200

# =========================
# CREATE TRIGGER
# =========================

@switch_bp.route("/<int:switch_id>/triggers", methods=["POST"])
@token_required
def create_trigger(switch_id):
    data = request.get_json(silent=True) or {}

    trigger_type = data.get("type")
    target = data.get("target")

    if trigger_type not in ["EMAIL", "WEBHOOK", "WHATSAPP"]:
        return jsonify({
            "success": False,
            "message": "type harus EMAIL, WEBHOOK, atau WHATSAPP"
        }), 400

    if not target:
        return jsonify({
            "success": False,
            "message": "target wajib diisi"
        }), 400

    if trigger_type == "WEBHOOK":
        if not (target.startswith("http://") or target.startswith("https://")):
            return jsonify({
                "success": False,
                "message": "target untuk WEBHOOK harus berupa URL valid (http/https)"
            }), 400

    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            # Pastikan switch milik user
            cursor.execute(
                """
                SELECT id
                FROM switches
                WHERE id = %s
                  AND user_id = %s
                """,
                (switch_id, g.user_id)
            )

            switch = cursor.fetchone()

            if not switch:
                return jsonify({
                    "success": False,
                    "message": "Switch tidak ditemukan"
                }), 404

            cursor.execute(
                """
                INSERT INTO triggers (
                    switch_id,
                    type,
                    target
                )
                VALUES (%s, %s, %s)
                """,
                (
                    switch_id,
                    trigger_type,
                    target
                )
            )

            trigger_id = cursor.lastrowid

            connection.commit()

            return jsonify({
                "success": True,
                "message": "Trigger berhasil dibuat",
                "data": {
                    "id": trigger_id,
                    "switch_id": switch_id,
                    "type": trigger_type,
                    "target": target,
                    "is_enabled": True
                }
            }), 201

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()


# =========================
# GET TRIGGERS
# =========================

@switch_bp.route("/<int:switch_id>/triggers", methods=["GET"])
@token_required
def get_triggers(switch_id):

    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            # Pastikan switch milik user
            cursor.execute(
                """
                SELECT id
                FROM switches
                WHERE id = %s
                  AND user_id = %s
                """,
                (switch_id, g.user_id)
            )

            switch = cursor.fetchone()

            if not switch:
                return jsonify({
                    "success": False,
                    "message": "Switch tidak ditemukan"
                }), 404

            cursor.execute(
                """
                SELECT
                    id,
                    switch_id,
                    type,
                    target,
                    payload,
                    is_enabled,
                    created_at,
                    updated_at
                FROM triggers
                WHERE switch_id = %s
                ORDER BY id ASC
                """,
                (switch_id,)
            )

            triggers = cursor.fetchall()

            return jsonify({
                "success": True,
                "data": triggers
            }), 200

    finally:
        connection.close()

# =========================
# UPDATE TRIGGER
# =========================

@switch_bp.route("/triggers/<int:trigger_id>", methods=["PUT"])
@token_required
def update_trigger(trigger_id):

    data = request.get_json(silent=True) or {}

    target = data.get("target")
    is_enabled = data.get("is_enabled")

    if target is None and is_enabled is None:
        return jsonify({
            "success": False,
            "message": "Tidak ada data yang diubah"
        }), 400

    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            # Cari trigger sekaligus pastikan ownership
            cursor.execute(
                """
                SELECT
                    t.id,
                    t.switch_id
                FROM triggers t
                INNER JOIN switches s
                    ON s.id = t.switch_id
                WHERE t.id = %s
                  AND s.user_id = %s
                """,
                (trigger_id, g.user_id)
            )

            trigger = cursor.fetchone()

            if not trigger:
                return jsonify({
                    "success": False,
                    "message": "Trigger tidak ditemukan"
                }), 404

            fields = []
            values = []

            if target is not None:
                if not target:
                    return jsonify({
                        "success": False,
                        "message": "target tidak boleh kosong"
                    }), 400

                fields.append("target = %s")
                values.append(target)

            if is_enabled is not None:

                if not isinstance(is_enabled, bool):
                    return jsonify({
                        "success": False,
                        "message": "is_enabled harus boolean"
                    }), 400

                fields.append("is_enabled = %s")
                values.append(is_enabled)

            values.append(trigger_id)

            query = f"""
                UPDATE triggers
                SET {", ".join(fields)}
                WHERE id = %s
            """

            cursor.execute(query, values)

            connection.commit()

            return jsonify({
                "success": True,
                "message": "Trigger berhasil diperbarui"
            }), 200

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()

# =========================
# DELETE TRIGGER
# =========================

@switch_bp.route("/triggers/<int:trigger_id>", methods=["DELETE"])
@token_required
def delete_trigger(trigger_id):

    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute(
                """
                SELECT
                    t.id
                FROM triggers t
                INNER JOIN switches s
                    ON s.id = t.switch_id
                WHERE t.id = %s
                  AND s.user_id = %s
                """,
                (trigger_id, g.user_id)
            )

            trigger = cursor.fetchone()

            if not trigger:
                return jsonify({
                    "success": False,
                    "message": "Trigger tidak ditemukan"
                }), 404

            cursor.execute(
                """
                DELETE FROM triggers
                WHERE id = %s
                """,
                (trigger_id,)
            )

            connection.commit()

            return jsonify({
                "success": True,
                "message": "Trigger berhasil dihapus"
            }), 200

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()

# =========================
# GET SWITCH EVENTS
# =========================

@switch_bp.route("/<int:switch_id>/events", methods=["GET"])
@token_required
def get_switch_events(switch_id):

    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            # Pastikan switch milik user
            cursor.execute(
                """
                SELECT id
                FROM switches
                WHERE id = %s
                  AND user_id = %s
                """,
                (switch_id, g.user_id)
            )

            switch = cursor.fetchone()

            if not switch:
                return jsonify({
                    "success": False,
                    "message": "Switch tidak ditemukan"
                }), 404

            # Ambil history
            cursor.execute(
                """
                SELECT
                    id,
                    switch_id,
                    user_id,
                    event_type,
                    description,
                    metadata,
                    created_at
                FROM switch_events
                WHERE switch_id = %s
                ORDER BY created_at DESC, id DESC
                """,
                (switch_id,)
            )

            events = cursor.fetchall()

            return jsonify({
                "success": True,
                "data": events
            }), 200

    finally:
        connection.close()


# =========================
# GET SINGLE EVENT
# =========================

@switch_bp.route(
    "/<int:switch_id>/events/<int:event_id>",
    methods=["GET"]
)
@token_required
def get_switch_event(switch_id, event_id):

    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute(
                """
                SELECT
                    e.id,
                    e.switch_id,
                    e.user_id,
                    e.event_type,
                    e.description,
                    e.metadata,
                    e.created_at
                FROM switch_events e
                INNER JOIN switches s
                    ON s.id = e.switch_id
                WHERE e.id = %s
                  AND e.switch_id = %s
                  AND s.user_id = %s
                """,
                (
                    event_id,
                    switch_id,
                    g.user_id
                )
            )

            event = cursor.fetchone()

            if not event:
                return jsonify({
                    "success": False,
                    "message": "Event tidak ditemukan"
                }), 404

            return jsonify({
                "success": True,
                "data": event
            }), 200

    finally:
        connection.close()