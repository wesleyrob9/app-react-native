from flask import Flask, jsonify
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flasgger import Swagger

from app.config import Config
from app.database import db, migrate
from app.socketio_setup import socketio
from app.swagger import swagger_config, swagger_template

limiter = Limiter(key_func=get_remote_address)


def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    db.init_app(app)
    migrate.init_app(app, db)
    socketio.init_app(app, cors_allowed_origins="*")
    limiter.init_app(app)
    Swagger(app, config=swagger_config, template=swagger_template)

    from app import models  # noqa: F401

    @app.route('/api/health')
    def health():
        try:
            db.session.execute(db.text('SELECT 1'))
            db_status = 'ok'
        except Exception:
            db_status = 'erro'
        return jsonify({'status': 'ok', 'database': db_status})

    from app.blueprints.auth import auth_bp
    from app.blueprints.grupos import grupos_bp
    from app.blueprints.eventos import eventos_bp
    from app.blueprints.sorteador import sorteador_bp
    from app.blueprints.notificacoes import notificacoes_bp
    app.register_blueprint(auth_bp)
    app.register_blueprint(grupos_bp)
    app.register_blueprint(eventos_bp)
    app.register_blueprint(sorteador_bp)
    app.register_blueprint(notificacoes_bp)

    return app
