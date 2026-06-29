from flask import g, jsonify, request

from app.blueprints.eventos import eventos_bp
from app.services import evento_service
from app.utils.decorators import membro_required, admin_required


@eventos_bp.route('/<int:grupo_id>/eventos', methods=['POST'])
@admin_required
def criar_evento(grupo_id):
    dados = request.get_json(silent=True) or {}
    resultado, status = evento_service.criar_evento(grupo_id, dados)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos', methods=['GET'])
@membro_required
def listar_eventos(grupo_id):
    resultado, status = evento_service.listar_eventos(grupo_id)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>', methods=['GET'])
@membro_required
def obter_evento(grupo_id, evento_id):
    resultado, status = evento_service.obter_evento(grupo_id, evento_id)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>', methods=['PUT'])
@admin_required
def editar_evento(grupo_id, evento_id):
    dados = request.get_json(silent=True) or {}
    resultado, status = evento_service.editar_evento(grupo_id, evento_id, dados)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/cancelar', methods=['PUT'])
@admin_required
def cancelar_evento(grupo_id, evento_id):
    dados = request.get_json(silent=True) or {}
    resultado, status = evento_service.cancelar_evento(grupo_id, evento_id, dados)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/encerrar', methods=['PUT'])
@admin_required
def encerrar_confirmacoes(grupo_id, evento_id):
    resultado, status = evento_service.encerrar_confirmacoes(grupo_id, evento_id)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/reabrir', methods=['PUT'])
@admin_required
def reabrir_confirmacoes(grupo_id, evento_id):
    resultado, status = evento_service.reabrir_confirmacoes(grupo_id, evento_id)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/presenca', methods=['POST'])
@membro_required
def responder_presenca(grupo_id, evento_id):
    dados = request.get_json(silent=True) or {}
    resultado, status = evento_service.responder_presenca(grupo_id, evento_id, g.user_id, dados)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/participantes', methods=['GET'])
@membro_required
def listar_participantes(grupo_id, evento_id):
    resultado, status = evento_service.listar_participantes(grupo_id, evento_id)
    return jsonify(resultado), status
