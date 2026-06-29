from flask import Blueprint

grupos_bp = Blueprint('grupos', __name__, url_prefix='/api/grupos')

from app.blueprints.grupos import routes  # noqa: E402, F401
