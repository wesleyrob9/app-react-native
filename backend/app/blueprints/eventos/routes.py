from flask import g, jsonify, request

from app.blueprints.eventos import eventos_bp
from app.services import evento_service
from app.utils.decorators import membro_required, admin_required


@eventos_bp.route('/<int:grupo_id>/eventos', methods=['POST'])
@admin_required
def criar_evento(grupo_id):
    """Cria um novo evento no grupo
    ---
    tags:
      - Eventos
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
            titulo:
              type: string
            data_hora:
              type: string
            local:
              type: string
    responses:
      201:
        description: Evento criado com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = evento_service.criar_evento(grupo_id, dados)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos', methods=['GET'])
@membro_required
def listar_eventos(grupo_id):
    """Lista os eventos do grupo
    ---
    tags:
      - Eventos
    security:
      - Bearer: []
    parameters:
      - in: path
        name: grupo_id
        type: integer
        required: true
    responses:
      200:
        description: Lista de eventos
      403:
        description: Usuário não é membro do grupo
    """
    resultado, status = evento_service.listar_eventos(grupo_id)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>', methods=['GET'])
@membro_required
def obter_evento(grupo_id, evento_id):
    """Obtém os dados de um evento
    ---
    tags:
      - Eventos
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
        description: Dados do evento
      403:
        description: Usuário não é membro do grupo
      404:
        description: Evento não encontrado
    """
    resultado, status = evento_service.obter_evento(grupo_id, evento_id)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>', methods=['PUT'])
@admin_required
def editar_evento(grupo_id, evento_id):
    """Edita os dados de um evento
    ---
    tags:
      - Eventos
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
        required: true
        schema:
          type: object
          properties:
            titulo:
              type: string
            data_hora:
              type: string
            local:
              type: string
    responses:
      200:
        description: Evento atualizado com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = evento_service.editar_evento(grupo_id, evento_id, dados)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/cancelar', methods=['PUT'])
@admin_required
def cancelar_evento(grupo_id, evento_id):
    """Cancela um evento
    ---
    tags:
      - Eventos
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
            motivo:
              type: string
    responses:
      200:
        description: Evento cancelado com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = evento_service.cancelar_evento(grupo_id, evento_id, dados)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/encerrar', methods=['PUT'])
@admin_required
def encerrar_confirmacoes(grupo_id, evento_id):
    """Encerra as confirmações de presença do evento
    ---
    tags:
      - Eventos
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
        description: Confirmações encerradas com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    resultado, status = evento_service.encerrar_confirmacoes(grupo_id, evento_id)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/reabrir', methods=['PUT'])
@admin_required
def reabrir_confirmacoes(grupo_id, evento_id):
    """Reabre as confirmações de presença do evento
    ---
    tags:
      - Eventos
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
        description: Confirmações reabertas com sucesso
      403:
        description: Usuário não é administrador do grupo
    """
    resultado, status = evento_service.reabrir_confirmacoes(grupo_id, evento_id)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/presenca', methods=['POST'])
@membro_required
def responder_presenca(grupo_id, evento_id):
    """Confirma ou recusa presença em um evento
    ---
    tags:
      - Eventos
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
        required: true
        schema:
          type: object
          properties:
            confirmado:
              type: boolean
    responses:
      200:
        description: Resposta de presença registrada com sucesso
      403:
        description: Usuário não é membro do grupo
    """
    dados = request.get_json(silent=True) or {}
    resultado, status = evento_service.responder_presenca(grupo_id, evento_id, g.user_id, dados)
    return jsonify(resultado), status


@eventos_bp.route('/<int:grupo_id>/eventos/<int:evento_id>/participantes', methods=['GET'])
@membro_required
def listar_participantes(grupo_id, evento_id):
    """Lista os participantes confirmados em um evento
    ---
    tags:
      - Eventos
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
        description: Lista de participantes
      403:
        description: Usuário não é membro do grupo
    """
    resultado, status = evento_service.listar_participantes(grupo_id, evento_id)
    return jsonify(resultado), status
