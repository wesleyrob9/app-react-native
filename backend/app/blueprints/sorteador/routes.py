from flask import jsonify, request

from app.blueprints.sorteador import sorteador_bp
from app.services import sorteio_service
from app.utils.decorators import membro_required, admin_required


@sorteador_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/sorteio', methods=['POST'])
@admin_required
def criar_sorteio(grupo_id, evento_id):
    """Realiza o sorteio de times para um evento
    ---
    tags:
      - Sorteio
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
      - in: path
        name: evento_id
        type: integer
        required: true
      - in: body
        name: body
        required: false
        schema:
          type: object
          properties:
            numero_times:
              type: integer
    responses:
      201:
        description: Sorteio criado com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = sorteio_service.criar_sorteio(grupo_id, evento_id, dados)
    return jsonify(resultado), status


@sorteador_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/sorteio', methods=['GET'])
@membro_required
def obter_sorteio(grupo_id, evento_id):
    """Obtém o sorteio de um evento
    ---
    tags:
      - Sorteio
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
      - in: path
        name: evento_id
        type: integer
        required: true
    responses:
      200:
        description: Dados do sorteio
      403:
        description: Usuário não é membro do grupo
      404:
        description: Sorteio não encontrado
    """
    resultado, status = sorteio_service.obter_sorteio(grupo_id, evento_id)
    return jsonify(resultado), status


@sorteador_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/sorteio/confirmar', methods=['PUT'])
@admin_required
def confirmar_sorteio(grupo_id, evento_id):
    """Confirma o sorteio realizado
    ---
    tags:
      - Sorteio
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
      - in: path
        name: evento_id
        type: integer
        required: true
    responses:
      200:
        description: Sorteio confirmado com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    resultado, status = sorteio_service.confirmar_sorteio(grupo_id, evento_id)
    return jsonify(resultado), status
