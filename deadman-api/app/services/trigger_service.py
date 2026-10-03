from datetime import datetime, timedelta

import resend

from app.config import Config
from app.db import get_db_connection


MAX_RETRY = 3


def send_email_trigger(trigger, switch, event):
    resend.api_key = Config.RESEND_API_KEY

    params = {
        "from": Config.MAIL_FROM,
        "to": [trigger["target"]],
        "subject": "Dead Man's Switch - Alert",
        "html": f"""
            <h2>Dead Man's Switch Alert</h2>

            <p>
                This is an automated alert from your Dead Man's Switch.
            </p>

            <p>
                Switch: <strong>{switch["name"]}</strong>
            </p>

            <p>
                The switch has entered the <strong>TRIGGERED</strong> state.
            </p>

            <p>
                Triggered at: {switch["triggered_at"]}
            </p>

            <hr>

            <p>
                This email was sent automatically by Dead Man's Switch.
            </p>
        """
    }

    return resend.Emails.send(params)


def send_webhook_trigger(trigger, switch, event):
    import requests
    
    payload = {
        "event": "DEADMAN_SWITCH_TRIGGERED",
        "switch_id": switch["id"],
        "switch_name": switch["name"],
        "triggered_at": str(switch["triggered_at"]),
        "metadata": trigger.get("payload")
    }
    
    response = requests.post(
        trigger["target"],
        json=payload,
        timeout=10
    )
    
    response.raise_for_status()
    return {"id": f"webhook-{datetime.now().timestamp()}"}


def send_whatsapp_trigger(trigger, switch, event):
    # Simulasi WhatsApp
    # Di masa depan bisa menggunakan API Fonnte / Twilio
    print(f"--- SIMULASI WHATSAPP ---")
    print(f"TO: {trigger['target']}")
    print(f"MSG: Switch {switch['name']} telah TRIGGERED!")
    print(f"--------------------------")
    
    return {"id": f"wa-sim-{datetime.now().timestamp()}"}


def process_triggers():
    connection = get_db_connection()

    result = {
        "processed": 0,
        "sent": 0,
        "failed": 0,
        "skipped": 0,
        "retried": 0
    }

    try:
        with connection.cursor() as cursor:

            # =========================================================
            # 1. Cari event TRIGGERED yang belum memiliki delivery
            # =========================================================

            cursor.execute(
                """
                SELECT
                    e.id AS event_id,
                    e.switch_id,
                    e.user_id
                FROM switch_events e
                LEFT JOIN trigger_deliveries d
                    ON d.event_id = e.id
                WHERE e.event_type = 'TRIGGERED'
                  AND d.id IS NULL
                ORDER BY e.created_at ASC
                LIMIT 50
                """
            )

            events = cursor.fetchall()

            for event in events:

                # =====================================================
                # 2. Cari trigger EMAIL aktif
                # =====================================================

                cursor.execute(
                    """
                    SELECT
                        id,
                        switch_id,
                        type,
                        target,
                        payload
                    FROM triggers
                    WHERE switch_id = %s
                      AND type IN ('EMAIL', 'WEBHOOK', 'WHATSAPP')
                      AND is_enabled = TRUE
                    """,
                    (event["switch_id"],)
                )

                triggers = cursor.fetchall()

                if not triggers:
                    result["skipped"] += 1
                    continue

                # =====================================================
                # 3. Ambil data switch
                # =====================================================

                cursor.execute(
                    """
                    SELECT
                        id,
                        name,
                        triggered_at
                    FROM switches
                    WHERE id = %s
                    """,
                    (event["switch_id"],)
                )

                switch = cursor.fetchone()

                if not switch:
                    result["skipped"] += 1
                    continue

                # =====================================================
                # 4. Buat delivery untuk setiap trigger
                # =====================================================

                for trigger in triggers:

                    cursor.execute(
                        """
                        INSERT IGNORE INTO trigger_deliveries (
                            trigger_id,
                            switch_id,
                            event_id,
                            status
                        )
                        VALUES (%s, %s, %s, 'PENDING')
                        """,
                        (
                            trigger["id"],
                            event["switch_id"],
                            event["event_id"]
                        )
                    )

                    # Kalau sudah ada delivery, skip
                    if cursor.rowcount == 0:
                        result["skipped"] += 1
                        continue

                    delivery_id = cursor.lastrowid

                    # Commit agar delivery tercatat
                    # sebelum menghubungi Resend
                    connection.commit()

                    result["processed"] += 1

                    # =================================================
                    # 5. Proses delivery
                    # =================================================

                    try:

                        with connection.cursor() as update_cursor:

                            update_cursor.execute(
                                """
                                UPDATE trigger_deliveries
                                SET
                                    status = 'PROCESSING',
                                    attempts = attempts + 1,
                                    locked_at = %s
                                WHERE id = %s
                                  AND status = 'PENDING'
                                  AND attempts < %s
                                """,
                                (
                                    datetime.now(),
                                    delivery_id,
                                    MAX_RETRY
                                )
                            )

                            updated = update_cursor.rowcount

                            connection.commit()

                        # Kalau tidak berhasil mengubah ke PROCESSING
                        if updated == 0:
                            result["skipped"] += 1
                            continue

                        # =============================================
                        # 6. Kirim Trigger sesuai tipe
                        # =============================================

                        if trigger["type"] == "EMAIL":
                            response = send_email_trigger(trigger, switch, event)
                        elif trigger["type"] == "WEBHOOK":
                            response = send_webhook_trigger(trigger, switch, event)
                        elif trigger["type"] == "WHATSAPP":
                            response = send_whatsapp_trigger(trigger, switch, event)
                        else:
                            raise Exception(f"Unsupported trigger type: {trigger['type']}")

                        # =============================================
                        # 7. Ambil provider message ID
                        # =============================================

                        provider_message_id = None

                        if isinstance(response, dict):
                            provider_message_id = response.get("id")

                        # =============================================
                        # 8. Tandai SENT
                        # =============================================

                        with connection.cursor() as update_cursor:

                            update_cursor.execute(
                                """
                                UPDATE trigger_deliveries
                                SET
                                    status = 'SENT',
                                    provider_message_id = %s,
                                    sent_at = %s,
                                    locked_at = NULL,
                                    error_message = NULL
                                WHERE id = %s
                                """,
                                (
                                    provider_message_id,
                                    datetime.now(),
                                    delivery_id
                                )
                            )

                            connection.commit()

                        result["sent"] += 1

                    except Exception as e:

                        # =============================================
                        # 9. Kalau gagal, cek jumlah attempts
                        # =============================================

                        with connection.cursor() as update_cursor:

                            update_cursor.execute(
                                """
                                SELECT attempts
                                FROM trigger_deliveries
                                WHERE id = %s
                                """,
                                (delivery_id,)
                            )

                            delivery = update_cursor.fetchone()

                            attempts = delivery["attempts"] if delivery else MAX_RETRY

                            # =========================================
                            # Masih boleh retry
                            # =========================================

                            if attempts < MAX_RETRY:

                                update_cursor.execute(
                                    """
                                    UPDATE trigger_deliveries
                                    SET
                                        status = 'PENDING',
                                        locked_at = NULL,
                                        error_message = %s
                                    WHERE id = %s
                                    """,
                                    (
                                        str(e),
                                        delivery_id
                                    )
                                )

                                result["retried"] += 1

                            # =========================================
                            # Sudah mencapai batas retry
                            # =========================================

                            else:

                                update_cursor.execute(
                                    """
                                    UPDATE trigger_deliveries
                                    SET
                                        status = 'FAILED',
                                        locked_at = NULL,
                                        error_message = %s
                                    WHERE id = %s
                                    """,
                                    (
                                        str(e),
                                        delivery_id
                                    )
                                )

                                result["failed"] += 1

                            connection.commit()

        return result

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()


def recover_stuck_deliveries():

    connection = get_db_connection()

    try:

        with connection.cursor() as cursor:

            cursor.execute(
                """
                UPDATE trigger_deliveries
                SET
                    status = 'PENDING',
                    locked_at = NULL
                WHERE status = 'PROCESSING'
                  AND locked_at IS NOT NULL
                  AND locked_at <= %s
                """,
                (
                    datetime.now() - timedelta(minutes=10),
                )
            )

            recovered = cursor.rowcount

            connection.commit()

            return recovered

    except Exception:

        connection.rollback()
        raise

    finally:

        connection.close()