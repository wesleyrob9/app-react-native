from flask import Blueprint

notificacoes_bp = Blueprint('notificacoes', __name__, url_prefix='/api/notificacoes')

from app.blueprints.notificacoes import routes  # noqa: E402, F401
