from datetime import datetime, timedelta

from app.db import get_db_connection

def create_switch_event(
    cursor,
    switch_id,
    user_id,
    event_type,
    description,
    metadata=None
):
    cursor.execute(
        """
        INSERT INTO switch_events (
            switch_id,
            user_id,
            event_type,
            description,
            metadata
        )
        VALUES (%s, %s, %s, %s, %s)
        """,
        (
            switch_id,
            user_id,
            event_type,
            description,
            metadata
        )
    )

def create_switch(
    user_id,
    name,
    checkin_interval,
    grace_period
):
    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute(
                """
                INSERT INTO switches (
                    user_id,
                    name,
                    checkin_interval,
                    grace_period
                )
                VALUES (%s, %s, %s, %s)
                """,
                (
                    user_id,
                    name,
                    checkin_interval,
                    grace_period
                )
            )

            switch_id = cursor.lastrowid

            connection.commit()

            return switch_id

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()


def get_user_switches(user_id):
    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute(
                """
                SELECT
                    id,
                    name,
                    status,
                    checkin_interval,
                    grace_period,
                    last_checkin_at,
                    next_deadline_at,
                    armed_at,
                    triggered_at,
                    created_at,
                    updated_at
                FROM switches
                WHERE user_id = %s
                ORDER BY created_at DESC
                """,
                (user_id,)
            )

            return cursor.fetchall()

    finally:
        connection.close()


def get_switch_by_id(switch_id, user_id):
    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute(
                """
                SELECT
                    id,
                    user_id,
                    name,
                    status,
                    checkin_interval,
                    grace_period,
                    last_checkin_at,
                    next_deadline_at,
                    armed_at,
                    triggered_at,
                    created_at,
                    updated_at
                FROM switches
                WHERE id = %s
                  AND user_id = %s
                LIMIT 1
                """,
                (switch_id, user_id)
            )

            return cursor.fetchone()

    finally:
        connection.close()


def update_switch(
    switch_id,
    user_id,
    name,
    checkin_interval,
    grace_period
):
    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute(
                """
                UPDATE switches
                SET
                    name = %s,
                    checkin_interval = %s,
                    grace_period = %s
                WHERE id = %s
                  AND user_id = %s
                  AND status = 'DISARMED'
                """,
                (
                    name,
                    checkin_interval,
                    grace_period,
                    switch_id,
                    user_id
                )
            )

            updated = cursor.rowcount
            create_switch_event(
                        cursor,
                        switch_id,
                        user_id,
                        "ARMED",
                        "Switch berhasil diaktifkan",
                        None
                    )

            connection.commit()

            return updated

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()

        

def delete_switch(switch_id, user_id):
    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute(
                """
                DELETE FROM switches
                WHERE id = %s
                  AND user_id = %s
                  AND status = 'DISARMED'
                """,
                (switch_id, user_id)
            )

            deleted = cursor.rowcount

            connection.commit()

            return deleted

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()


def arm_switch(switch_id, user_id):
    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute(
                """
                SELECT
                    id,
                    name,
                    status,
                    checkin_interval,
                    grace_period
                FROM switches
                WHERE id = %s
                  AND user_id = %s
                LIMIT 1
                """,
                (switch_id, user_id)
            )

            switch = cursor.fetchone()

            if not switch:
                return None, "Switch tidak ditemukan"

            if switch["status"] != "DISARMED":
                return None, "Switch tidak dalam keadaan DISARMED"

            now = datetime.now()

            deadline = now + timedelta(
                minutes=switch["checkin_interval"]
            )

            cursor.execute(
                """
                UPDATE switches
                SET
                    status = 'ARMED',
                    last_checkin_at = %s,
                    next_deadline_at = %s,
                    grace_deadline_at = NULL,
                    armed_at = %s,
                    triggered_at = NULL
                WHERE id = %s
                  AND user_id = %s
                """,
                (
                    now,
                    deadline,
                    now,
                    switch_id,
                    user_id
                )
            )

            connection.commit()

            return {
                "id": switch["id"],
                "status": "ARMED",
                "last_checkin_at": now,
                "next_deadline_at": deadline
            }, None

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()


def disarm_switch(switch_id, user_id):
    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute(
                """
                UPDATE switches
                SET
                    status = 'DISARMED',
                    last_checkin_at = NULL,
                    next_deadline_at = NULL,
                    grace_deadline_at = NULL,
                    armed_at = NULL
                WHERE id = %s
                  AND user_id = %s
                  AND status IN ('ARMED', 'GRACE')
                """,
                (switch_id, user_id)
            )

            updated = cursor.rowcount
            create_switch_event(
                        cursor,
                        switch_id,
                        user_id,
                        "DISARMED",
                        "Switch berhasil dinonaktifkan",
                        None
                    )
            connection.commit()

            return updated

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()
        

def checkin_switch(switch_id, user_id, source="MOBILE", ip_address=None, device_id=None):
    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:

            # Ambil switch
            cursor.execute(
                """
                SELECT
                    id,
                    status,
                    checkin_interval,
                    grace_period
                FROM switches
                WHERE id = %s
                  AND user_id = %s
                LIMIT 1
                """,
                (switch_id, user_id)
            )

            switch = cursor.fetchone()

            if not switch:
                return None, "Switch tidak ditemukan"

            # Check-in hanya boleh ketika ARMED / GRACE
            if switch["status"] not in ("ARMED", "GRACE"):
                return None, "Switch tidak sedang aktif"

            now = datetime.now()

            # Reset deadline
            next_deadline = now + timedelta(
                minutes=switch["checkin_interval"]
            )

            # Setelah check-in, kembali ARMED
            cursor.execute(
                """
                UPDATE switches
                SET
                    status = 'ARMED',
                    last_checkin_at = %s,
                    next_deadline_at = %s
                WHERE id = %s
                  AND user_id = %s
                """,
                (
                    now,
                    next_deadline,
                    switch_id,
                    user_id
                )
            )

            # Simpan riwayat check-in
            cursor.execute(
                """
                INSERT INTO checkins (
                    switch_id,
                    user_id,
                    checked_in_at,
                    source,
                    ip_address,
                    device_id
                )
                VALUES (%s, %s, %s, %s, %s, %s)
                """,
                (
                    switch_id,
                    user_id,
                    now,
                    source,
                    ip_address,
                    device_id
                )
            )
            create_switch_event(
            cursor,
            switch_id,
            user_id,
            "CHECKIN",
            "User melakukan check-in",
            None
        )

            connection.commit()

            return {
                "id": switch_id,
                "status": "ARMED",
                "last_checkin_at": now,
                "next_deadline_at": next_deadline
            }, None

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()
        