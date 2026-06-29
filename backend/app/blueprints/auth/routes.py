from flask import g, jsonify, request

from app import limiter
from app.blueprints.auth import auth_bp
from app.services import auth_service
from app.utils.decorators import token_required


@auth_bp.route('/registro', methods=['POST'])
@limiter.limit('3/minute')
def registro():
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.registrar_usuario(dados)
    return jsonify(resultado), status


@auth_bp.route('/login', methods=['POST'])
@limiter.limit('5/minute')
def login():
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.login_usuario(dados)
    return jsonify(resultado), status


@auth_bp.route('/refresh', methods=['POST'])
def refresh():
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.refresh_access_token(dados)
    return jsonify(resultado), status


@auth_bp.route('/me', methods=['GET'])
@token_required
def get_perfil():
    resultado, status = auth_service.obter_perfil(g.user_id)
    return jsonify(resultado), status


@auth_bp.route('/me', methods=['PUT'])
@token_required
def atualizar_perfil():
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.atualizar_perfil(g.user_id, dados)
    return jsonify(resultado), status


@auth_bp.route('/alterar-senha', methods=['PUT'])
@token_required
def alterar_senha():
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.alterar_senha(g.user_id, dados)
    return jsonify(resultado), status


@auth_bp.route('/esqueci-senha', methods=['POST'])
@limiter.limit('3/minute')
def esqueci_senha():
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.solicitar_reset_senha(dados)
    return jsonify(resultado), status


@auth_bp.route('/redefinir-senha', methods=['POST'])
def redefinir_senha():
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.redefinir_senha(dados)
    return jsonify(resultado), status
