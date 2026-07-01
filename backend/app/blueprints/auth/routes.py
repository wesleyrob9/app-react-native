from flask import g, jsonify, request

from app import limiter
from app.blueprints.auth import auth_bp
from app.services import auth_service
from app.utils.decorators import token_required


@auth_bp.route('/registro', methods=['POST'])
@limiter.limit('3/minute')
def registro():
    """Registra um novo usuário
    ---
    tags:
      - Auth
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            nome:
              type: string
            email:
              type: string
            senha:
              type: string
    responses:
      201:
        description: Usuário criado com sucesso
      400:
        description: Dados inválidos
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.registrar_usuario(dados)
    return jsonify(resultado), status


@auth_bp.route('/login', methods=['POST'])
@limiter.limit('5/minute')
def login():
    """Autentica um usuário
    ---
    tags:
      - Auth
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            email:
              type: string
            senha:
              type: string
    responses:
      200:
        description: Login realizado com sucesso, retorna tokens de acesso
      401:
        description: Credenciais inválidas
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.login_usuario(dados)
    return jsonify(resultado), status


@auth_bp.route('/refresh', methods=['POST'])
def refresh():
    """Renova o token de acesso usando o refresh token
    ---
    tags:
      - Auth
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            refresh_token:
              type: string
    responses:
      200:
        description: Novo access token gerado
      401:
        description: Refresh token inválido ou expirado
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.refresh_access_token(dados)
    return jsonify(resultado), status


@auth_bp.route('/me', methods=['GET'])
@token_required
def get_perfil():
    """Obtém o perfil do usuário autenticado
    ---
    tags:
      - Auth
    security:
      - Bearer: []
    responses:
      200:
        description: Dados do perfil do usuário
      401:
        description: Não autenticado
    """
    resultado, status = auth_service.obter_perfil(g.user_id)
    return jsonify(resultado), status


@auth_bp.route('/me', methods=['PUT'])
@token_required
def atualizar_perfil():
    """Atualiza o perfil do usuário autenticado
    ---
    tags:
      - Auth
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            nome:
              type: string
            email:
              type: string
    responses:
      200:
        description: Perfil atualizado com sucesso
      401:
        description: Não autenticado
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.atualizar_perfil(g.user_id, dados)
    return jsonify(resultado), status


@auth_bp.route('/alterar-senha', methods=['PUT'])
@token_required
def alterar_senha():
    """Altera a senha do usuário autenticado
    ---
    tags:
      - Auth
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            senha_atual:
              type: string
            nova_senha:
              type: string
    responses:
      200:
        description: Senha alterada com sucesso
      401:
        description: Senha atual incorreta ou não autenticado
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.alterar_senha(g.user_id, dados)
    return jsonify(resultado), status


@auth_bp.route('/esqueci-senha', methods=['POST'])
@limiter.limit('3/minute')
def esqueci_senha():
    """Solicita o reset de senha por e-mail
    ---
    tags:
      - Auth
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            email:
              type: string
    responses:
      200:
        description: Solicitação processada (e-mail enviado se existir)
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.solicitar_reset_senha(dados)
    return jsonify(resultado), status


@auth_bp.route('/redefinir-senha', methods=['POST'])
def redefinir_senha():
    """Redefine a senha usando o token de reset
    ---
    tags:
      - Auth
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            token:
              type: string
            nova_senha:
              type: string
    responses:
      200:
        description: Senha redefinida com sucesso
      400:
        description: Token inválido ou expirado
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = auth_service.redefinir_senha(dados)
    return jsonify(resultado), status
