import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = int(os.getenv("DB_PORT", 3306))
    DB_USER = os.getenv("DB_USER", "root")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")
    DB_NAME = os.getenv("DB_NAME", "deadman_switch")

    JWT_SECRET = os.getenv("JWT_SECRET")
    JWT_EXPIRES_HOURS = int(os.getenv("JWT_EXPIRES_HOURS", 24))

    CRON_SECRET = os.getenv("CRON_SECRET")
    RESEND_API_KEY = os.getenv("RESEND_API_KEY")
    MAIL_FROM = os.getenv(
        "MAIL_FROM", 
        "onboarding@resend.dev"
        )