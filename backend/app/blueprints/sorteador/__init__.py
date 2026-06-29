from flask import Blueprint

sorteador_bp = Blueprint('sorteador', __name__, url_prefix='/api/grupos')

from app.blueprints.sorteador import routes  # noqa: E402, F401
