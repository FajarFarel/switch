from datetime import datetime, timedelta

from app.db import get_db_connection


def process_deadlines():
    connection = get_db_connection()

    result = {
        "armed_to_grace": 0,
        "grace_to_triggered": 0
    }

    try:
        with connection.cursor() as cursor:

            now = datetime.now()

            # =====================================================
            # 1. ARMED -> GRACE
            # =====================================================

            cursor.execute(
                """
                SELECT
                    id,
                    user_id,
                    grace_period
                FROM switches
                WHERE status = 'ARMED'
                  AND next_deadline_at IS NOT NULL
                  AND next_deadline_at <= %s
                FOR UPDATE
                """,
                (now,)
            )

            expired_switches = cursor.fetchall()

            for switch in expired_switches:

                grace_deadline = now + timedelta(
                    minutes=switch["grace_period"]
                )

                cursor.execute(
                    """
                    UPDATE switches
                    SET
                        status = 'GRACE',
                        grace_deadline_at = %s
                    WHERE id = %s
                      AND status = 'ARMED'
                    """,
                    (
                        grace_deadline,
                        switch["id"]
                    )
                )

                if cursor.rowcount > 0:

                    cursor.execute(
                        """
                        INSERT INTO switch_events (
                            switch_id,
                            user_id,
                            event_type,
                            description
                        )
                        VALUES (%s, %s, %s, %s)
                        """,
                        (
                            switch["id"],
                            switch["user_id"],
                            "GRACE_STARTED",
                            "Check-in deadline terlewat, switch masuk grace period"
                        )
                    )

                    result["armed_to_grace"] += 1

            # =====================================================
            # 2. GRACE -> TRIGGERED
            # =====================================================

            cursor.execute(
                """
                SELECT
                    id,
                    user_id
                FROM switches
                WHERE status = 'GRACE'
                  AND grace_deadline_at IS NOT NULL
                  AND grace_deadline_at <= %s
                FOR UPDATE
                """,
                (now,)
            )

            grace_expired_switches = cursor.fetchall()

            for switch in grace_expired_switches:

                cursor.execute(
                    """
                    UPDATE switches
                    SET
                        status = 'TRIGGERED',
                        triggered_at = %s
                    WHERE id = %s
                      AND status = 'GRACE'
                    """,
                    (
                        now,
                        switch["id"]
                    )
                )

                if cursor.rowcount > 0:

                    cursor.execute(
                        """
                        INSERT INTO switch_events (
                            switch_id,
                            user_id,
                            event_type,
                            description
                        )
                        VALUES (%s, %s, %s, %s)
                        """,
                        (
                            switch["id"],
                            switch["user_id"],
                            "TRIGGERED",
                            "Grace period habis, switch menjadi TRIGGERED"
                        )
                    )

                    result["grace_to_triggered"] += 1

            connection.commit()

            return result

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()