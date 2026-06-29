from flask import g, jsonify, request

from app.blueprints.notificacoes import notificacoes_bp
from app.services import notificacao_service
from app.utils.decorators import token_required


@notificacoes_bp.route('', methods=['GET'])
@token_required
def listar():
    apenas_nao_lidas = request.args.get('nao_lidas', '').lower() == 'true'
    resultado, status = notificacao_service.listar_notificacoes(g.user_id, apenas_nao_lidas)
    return jsonify(resultado), status


@notificacoes_bp.route('/contagem', methods=['GET'])
@token_required
def contagem():
    resultado, status = notificacao_service.contar_nao_lidas(g.user_id)
    return jsonify(resultado), status


@notificacoes_bp.route('/<int:notificacao_id>/lida', methods=['PUT'])
@token_required
def marcar_lida(notificacao_id):
    resultado, status = notificacao_service.marcar_como_lida(g.user_id, notificacao_id)
    return jsonify(resultado), status


@notificacoes_bp.route('/lidas', methods=['PUT'])
@token_required
def marcar_todas_lidas():
    resultado, status = notificacao_service.marcar_todas_como_lidas(g.user_id)
    return jsonify(resultado), status
