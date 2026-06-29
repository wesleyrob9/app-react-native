from flask import Blueprint

eventos_bp = Blueprint('eventos', __name__, url_prefix='/api/grupos')

from app.blueprints.eventos import routes  # noqa: E402, F401
