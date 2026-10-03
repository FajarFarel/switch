import bcrypt
import jwt

from datetime import datetime, timedelta, timezone

from app.config import Config


def hash_password(password: str) -> str:
    hashed = bcrypt.hashpw(
        password.encode("utf-8"),
        bcrypt.gensalt()
    )

    return hashed.decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    return bcrypt.checkpw(
        password.encode("utf-8"),
        password_hash.encode("utf-8")
    )


def create_token(user_id: int) -> str:
    now = datetime.now(timezone.utc)

    payload = {
        "user_id": user_id,
        "iat": now,
        "exp": now + timedelta(
            hours=Config.JWT_EXPIRES_HOURS
        )
    }

    return jwt.encode(
        payload,
        Config.JWT_SECRET,
        algorithm="HS256"
    )


def decode_token(token: str):
    try:
        return jwt.decode(
            token,
            Config.JWT_SECRET,
            algorithms=["HS256"]
        )
    except jwt.InvalidTokenError:
        return None