from flask import g, jsonify, request

from app.blueprints.grupos import grupos_bp
from app.services import grupo_service, avaliacao_service
from app.utils.decorators import token_required, membro_required, admin_required


@grupos_bp.route('', methods=['POST'])
@token_required
def criar_grupo():
    """Cria um novo grupo
    ---
    tags:
      - Grupos
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
            descricao:
              type: string
    responses:
      201:
        description: Grupo criado com sucesso
      401:
        description: Não autenticado
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = grupo_service.criar_grupo(g.user_id, dados)
    return jsonify(resultado), status


@grupos_bp.route('', methods=['GET'])
@token_required
def listar_grupos():
    """Lista os grupos do usuário autenticado
    ---
    tags:
      - Grupos
    security:
      - Bearer: []
    responses:
      200:
        description: Lista de grupos
      401:
        description: Não autenticado
    """
    resultado, status = grupo_service.listar_meus_grupos(g.user_id)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>', methods=['GET'])
@membro_required
def obter_grupo(grupo_id):
    """Obtém os dados de um grupo
    ---
    tags:
      - Grupos
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
    responses:
      200:
        description: Dados do grupo
      403:
        description: Usuário não é membro do grupo
      404:
        description: Grupo não encontrado
    """
    resultado, status = grupo_service.obter_grupo(grupo_id, g.membro.papel)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>', methods=['PUT'])
@admin_required
def editar_grupo(grupo_id):
    """Edita os dados de um grupo
    ---
    tags:
      - Grupos
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            nome:
              type: string
            descricao:
              type: string
    responses:
      200:
        description: Grupo atualizado com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = grupo_service.editar_grupo(grupo_id, dados)
    return jsonify(resultado), status


@grupos_bp.route('/entrar', methods=['POST'])
@token_required
def solicitar_entrada():
    """Solicita entrada em um grupo
    ---
    tags:
      - Grupos
    security:
      - Bearer: []
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            codigo_convite:
              type: string
    responses:
      200:
        description: Solicitação enviada com sucesso
      401:
        description: Não autenticado
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = grupo_service.solicitar_entrada(g.user_id, dados)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/membros', methods=['GET'])
@membro_required
def listar_membros(grupo_id):
    """Lista os membros de um grupo
    ---
    tags:
      - Grupos
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
    responses:
      200:
        description: Lista de membros
      403:
        description: Usuário não é membro do grupo
    """
    resultado, status = grupo_service.listar_membros(grupo_id)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/pendentes', methods=['GET'])
@admin_required
def listar_pendentes(grupo_id):
    """Lista as solicitações de entrada pendentes
    ---
    tags:
      - Grupos
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
    responses:
      200:
        description: Lista de solicitações pendentes
      403:
        description: Usuário não é administrador do grupo
    """
    resultado, status = grupo_service.listar_pendentes(grupo_id)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/membros/<int:uid>/aprovar', methods=['PUT'])
@admin_required
def aprovar_membro(grupo_id, uid):
    """Aprova a entrada de um membro no grupo
    ---
    tags:
      - Grupos
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
      - in: path
        name: uid
        type: integer
        required: true
    responses:
      200:
        description: Membro aprovado com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    resultado, status = grupo_service.aprovar_membro(grupo_id, uid)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/membros/<int:uid>/rejeitar', methods=['PUT'])
@admin_required
def rejeitar_membro(grupo_id, uid):
    """Rejeita a entrada de um membro no grupo
    ---
    tags:
      - Grupos
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
      - in: path
        name: uid
        type: integer
        required: true
    responses:
      200:
        description: Membro rejeitado com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    resultado, status = grupo_service.rejeitar_membro(grupo_id, uid)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/membros/<int:uid>/promover', methods=['PUT'])
@admin_required
def promover_membro(grupo_id, uid):
    """Promove um membro a administrador do grupo
    ---
    tags:
      - Grupos
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
      - in: path
        name: uid
        type: integer
        required: true
    responses:
      200:
        description: Membro promovido com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    resultado, status = grupo_service.promover_membro(grupo_id, uid)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/membros/<int:uid>/rebaixar', methods=['PUT'])
@admin_required
def rebaixar_admin(grupo_id, uid):
    """Rebaixa um administrador a membro comum
    ---
    tags:
      - Grupos
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
      - in: path
        name: uid
        type: integer
        required: true
    responses:
      200:
        description: Administrador rebaixado com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    resultado, status = grupo_service.rebaixar_admin(grupo_id, uid)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/membros/<int:uid>', methods=['DELETE'])
@admin_required
def remover_membro(grupo_id, uid):
    """Remove um membro do grupo
    ---
    tags:
      - Grupos
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
      - in: path
        name: uid
        type: integer
        required: true
    responses:
      200:
        description: Membro removido com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    resultado, status = grupo_service.remover_membro(grupo_id, uid, g.user_id)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/sair', methods=['DELETE'])
@token_required
def sair_grupo(grupo_id):
    """Sai de um grupo
    ---
    tags:
      - Grupos
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
    responses:
      200:
        description: Saída do grupo realizada com sucesso
      401:
        description: Não autenticado
    """
    resultado, status = grupo_service.sair_do_grupo(grupo_id, g.user_id)
    return jsonify(resultado), status


# === AVALIACOES (RF-014 a RF-016) ===

@grupos_bp.route('/<int:grupo_id>/avaliacoes', methods=['GET'])
@membro_required
def listar_avaliacoes(grupo_id):
    """Lista as avaliações dos jogadores do grupo
    ---
    tags:
      - Avaliações
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
    responses:
      200:
        description: Lista de avaliações
      403:
        description: Usuário não é membro do grupo
    """
    resultado, status = avaliacao_service.listar_avaliacoes(grupo_id)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/avaliacoes/<int:uid>', methods=['GET'])
@membro_required
def obter_avaliacao(grupo_id, uid):
    """Obtém a avaliação de um jogador
    ---
    tags:
      - Avaliações
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
      - in: path
        name: uid
        type: integer
        required: true
    responses:
      200:
        description: Dados da avaliação
      403:
        description: Usuário não é membro do grupo
      404:
        description: Avaliação não encontrada
    """
    resultado, status = avaliacao_service.obter_avaliacao(grupo_id, uid)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/avaliacoes/<int:uid>', methods=['PUT'])
@admin_required
def avaliar_jogador(grupo_id, uid):
    """Avalia um jogador do grupo
    ---
    tags:
      - Avaliações
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
      - in: path
        name: uid
        type: integer
        required: true
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            nota:
              type: number
    responses:
      200:
        description: Avaliação registrada com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = avaliacao_service.avaliar_jogador(grupo_id, uid, g.user_id, dados)
    return jsonify(resultado), status


@grupos_bp.route('/<int:grupo_id>/avaliacoes/<int:uid>/historico', methods=['GET'])
@membro_required
def historico_avaliacao(grupo_id, uid):
    """Obtém o histórico de avaliações de um jogador
    ---
    tags:
      - Avaliações
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
      - in: path
        name: uid
        type: integer
        required: true
    responses:
      200:
        description: Histórico de avaliações
      403:
        description: Usuário não é membro do grupo
    """
    resultado, status = avaliacao_service.historico_jogador(grupo_id, uid)
    return jsonify(resultado), status
