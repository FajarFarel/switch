from flask import Flask
from flask_cors import CORS
from app.routes.switch import switch_bp
from app.routes.internal import internal_bp
from app.routes.auth import auth_bp

def create_app():
    app = Flask(__name__)

    CORS(app)

    app.register_blueprint(
        auth_bp,
        url_prefix="/api/auth"
    )

    app.register_blueprint(
        switch_bp,
        url_prefix="/api/switch"
    )

    app.register_blueprint(
    internal_bp,
    url_prefix="/api/internal"
)
    @app.route("/api/status", methods=["GET"])
    def status():
        return {
            "success": True,
            "message": "Dead Man's Switch API is running"
        }

    return app