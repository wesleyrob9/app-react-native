from flask import jsonify, request

from app.blueprints.sorteador import sorteador_bp
from app.services import sorteio_service
from app.utils.decorators import membro_required, admin_required


@sorteador_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/sorteio', methods=['POST'])
@admin_required
def criar_sorteio(grupo_id, evento_id):
    dados = request.get_json(silent=True) or {}
    resultado, status = sorteio_service.criar_sorteio(grupo_id, evento_id, dados)
    return jsonify(resultado), status


@sorteador_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/sorteio', methods=['GET'])
@membro_required
def obter_sorteio(grupo_id, evento_id):
    resultado, status = sorteio_service.obter_sorteio(grupo_id, evento_id)
    return jsonify(resultado), status


@sorteador_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/sorteio/confirmar', methods=['PUT'])
@admin_required
def confirmar_sorteio(grupo_id, evento_id):
    resultado, status = sorteio_service.confirmar_sorteio(grupo_id, evento_id)
    return jsonify(resultado), status
