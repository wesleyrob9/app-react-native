from flask import g, jsonify, request

from app.blueprints.notificacoes import notificacoes_bp
from app.services import notificacao_service
from app.utils.decorators import token_required


@notificacoes_bp.route('', methods=['GET'])
@token_required
def listar():
    """Lista as notificações do usuário autenticado
    ---
    tags:
      - Notificações
    security:
      - Bearer: []
    parameters:
      - in: query
        name: nao_lidas
        type: boolean
        required: false
        description: Se true, retorna apenas notificações não lidas
    responses:
      200:
        description: Lista de notificações
      401:
        description: Não autenticado
    """
    apenas_nao_lidas = request.args.get('nao_lidas', '').lower() == 'true'
    resultado, status = notificacao_service.listar_notificacoes(g.user_id, apenas_nao_lidas)
    return jsonify(resultado), status


@notificacoes_bp.route('/contagem', methods=['GET'])
@token_required
def contagem():
    """Obtém a contagem de notificações não lidas
    ---
    tags:
      - Notificações
    security:
      - Bearer: []
    responses:
      200:
        description: Contagem de notificações não lidas
      401:
        description: Não autenticado
    """
    resultado, status = notificacao_service.contar_nao_lidas(g.user_id)
    return jsonify(resultado), status


@notificacoes_bp.route('/<int:notificacao_id>/lida', methods=['PUT'])
@token_required
def marcar_lida(notificacao_id):
    """Marca uma notificação como lida
    ---
    tags:
      - Notificações
    security:
      - Bearer: []
    parameters:
      - in: path
        name: notificacao_id
        type: integer
        required: true
    responses:
      200:
        description: Notificação marcada como lida
      401:
        description: Não autenticado
      404:
        description: Notificação não encontrada
    """
    resultado, status = notificacao_service.marcar_como_lida(g.user_id, notificacao_id)
    return jsonify(resultado), status


@notificacoes_bp.route('/lidas', methods=['PUT'])
@token_required
def marcar_todas_lidas():
    """Marca todas as notificações do usuário como lidas
    ---
    tags:
      - Notificações
    security:
      - Bearer: []
    responses:
      200:
        description: Notificações marcadas como lidas
      401:
        description: Não autenticado
    """
    resultado, status = notificacao_service.marcar_todas_como_lidas(g.user_id)
    return jsonify(resultado), status
