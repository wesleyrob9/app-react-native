from flask import g, jsonify, request

from app.blueprints.grupos import grupos_bp
from app.services import grupo_service, avaliacao_service
from app.utils.decorators import token_required, membro_required, admin_required


@grupos_bp.route('', methods=['POST'])
@token_required
def criar_grupo():
    dados = request.get_json(silent=True) or {}
    resultado, status = grupo_service.criar_grupo(g.user_id, dados)
    return jsonify(resultado), status


@grupos_bp.route('', methods=['GET'])
@token_required
def listar_grupos():
    resultado, status = grupo_service.listar_meus_grupos(g.user_id)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>', methods=['GET'])
@membro_required
def obter_grupo(grupo_id):
    resultado, status = grupo_service.obter_grupo(grupo_id, g.membro.papel)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>', methods=['PUT'])
@admin_required
def editar_grupo(grupo_id):
    dados = request.get_json(silent=True) or {}
    resultado, status = grupo_service.editar_grupo(grupo_id, dados)
    return jsonify(resultado), status


@grupos_bp.route('/entrar', methods=['POST'])
@token_required
def solicitar_entrada():
    dados = request.get_json(silent=True) or {}
    resultado, status = grupo_service.solicitar_entrada(g.user_id, dados)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/membros', methods=['GET'])
@membro_required
def listar_membros(grupo_id):
    resultado, status = grupo_service.listar_membros(grupo_id)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/pendentes', methods=['GET'])
@admin_required
def listar_pendentes(grupo_id):
    resultado, status = grupo_service.listar_pendentes(grupo_id)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/membros/<int:uid>/aprovar', methods=['PUT'])
@admin_required
def aprovar_membro(grupo_id, uid):
    resultado, status = grupo_service.aprovar_membro(grupo_id, uid)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/membros/<int:uid>/rejeitar', methods=['PUT'])
@admin_required
def rejeitar_membro(grupo_id, uid):
    resultado, status = grupo_service.rejeitar_membro(grupo_id, uid)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/membros/<int:uid>/promover', methods=['PUT'])
@admin_required
def promover_membro(grupo_id, uid):
    resultado, status = grupo_service.promover_membro(grupo_id, uid)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/membros/<int:uid>/rebaixar', methods=['PUT'])
@admin_required
def rebaixar_admin(grupo_id, uid):
    resultado, status = grupo_service.rebaixar_admin(grupo_id, uid)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/membros/<int:uid>', methods=['DELETE'])
@admin_required
def remover_membro(grupo_id, uid):
    resultado, status = grupo_service.remover_membro(grupo_id, uid, g.user_id)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/sair', methods=['DELETE'])
@token_required
def sair_grupo(grupo_id):
    resultado, status = grupo_service.sair_do_grupo(grupo_id, g.user_id)
    return jsonify(resultado), status


# === AVALIACOES (RF-014 a RF-016) ===

@grupos_bp.route('/<int:grupo_id>/avaliacoes', methods=['GET'])
@membro_required
def listar_avaliacoes(grupo_id):
    resultado, status = avaliacao_service.listar_avaliacoes(grupo_id)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/avaliacoes/<int:uid>', methods=['GET'])
@membro_required
def obter_avaliacao(grupo_id, uid):
    resultado, status = avaliacao_service.obter_avaliacao(grupo_id, uid)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/avaliacoes/<int:uid>', methods=['PUT'])
@admin_required
def avaliar_jogador(grupo_id, uid):
    dados = request.get_json(silent=True) or {}
    resultado, status = avaliacao_service.avaliar_jogador(grupo_id, uid, g.user_id, dados)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/avaliacoes/<int:uid>/historico', methods=['GET'])
@membro_required
def historico_avaliacao(grupo_id, uid):
    resultado, status = avaliacao_service.historico_jogador(grupo_id, uid)
    return jsonify(resultado), status
