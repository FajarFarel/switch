import resend

from app.config import Config


def send_test_email(to_email):
    resend.api_key = Config.RESEND_API_KEY

    params = {
        "from": Config.MAIL_FROM,
        "to": [to_email],
        "subject": "Dead Man's Switch - Test Email",
        "html": """
            <h2>Dead Man's Switch</h2>
            <p>Test email berhasil dikirim! 🚨</p>
            <p>Resend sudah terhubung dengan backend Flask.</p>
        """
    }

    response = resend.Emails.send(params)

    return response