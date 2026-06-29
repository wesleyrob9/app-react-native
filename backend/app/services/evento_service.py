from datetime import date, datetime, timezone

from app.database import db
from app.models.evento import Evento, EventoParticipante
from app.models.grupo import Grupo, GrupoMembro
from app.models.usuario import Usuario, PerfilJogador
from app.models.notificacao import Notificacao


def serializar_evento(evento: Evento) -> dict:
    confirmados = sum(1 for p in evento.participantes if p.resposta == 'confirmado')
    return {
        'id': evento.id,
        'grupo_id': evento.grupo_id,
        'nome': evento.nome,
        'data_evento': evento.data_evento.isoformat(),
        'horario': evento.horario.strftime('%H:%M'),
        'local': evento.local,
        'observacoes': evento.observacoes,
        'status_confirmacoes': evento.status_confirmacoes,
        'cancelado': evento.cancelado_em is not None,
        'motivo_cancelamento': evento.motivo_cancelamento,
        'is_active': evento.is_active,
        'created_at': evento.created_at.isoformat() if evento.created_at else None,
        'total_confirmados': confirmados,
        'total_participantes': len(evento.participantes),
    }


def criar_evento(grupo_id: int, dados: dict) -> tuple[dict, int]:
    nome = (dados.get('nome') or '').strip()
    data_evento = dados.get('data_evento')
    horario = dados.get('horario')
    local = (dados.get('local') or '').strip()
    observacoes = (dados.get('observacoes') or '').strip() or None

    if not nome or len(nome) < 3 or len(nome) > 100:
        return {'error': 'Nome deve ter entre 3 e 100 caracteres'}, 400

    if not data_evento:
        return {'error': 'Data do evento e obrigatoria'}, 400

    if not horario:
        return {'error': 'Horario e obrigatorio'}, 400

    if not local or len(local) > 255:
        return {'error': 'Local e obrigatorio (max 255 caracteres)'}, 400

    try:
        if isinstance(data_evento, str):
            data_evento = date.fromisoformat(data_evento)
    except ValueError:
        return {'error': 'Data invalida (formato: YYYY-MM-DD)'}, 400

    try:
        if isinstance(horario, str):
            from datetime import time
            parts = horario.split(':')
            horario = time(int(parts[0]), int(parts[1]))
    except (ValueError, IndexError):
        return {'error': 'Horario invalido (formato: HH:MM)'}, 400

    evento = Evento(
        grupo_id=grupo_id, nome=nome, data_evento=data_evento,
        horario=horario, local=local, observacoes=observacoes,
    )
    db.session.add(evento)
    db.session.flush()

    grupo = db.session.get(Grupo, grupo_id)
    membros = GrupoMembro.query.filter_by(grupo_id=grupo_id, status='aprovado').all()
    for m in membros:
        db.session.add(Notificacao(
            usuario_id=m.usuario_id, tipo='novo_evento',
            titulo=f'Novo evento: {nome} - {grupo.nome}',
            mensagem=f'{data_evento.strftime("%d/%m/%Y")} as {evento.horario.strftime("%H:%M")} em {local}',
            referencia_tipo='evento', referencia_id=evento.id,
        ))

    db.session.commit()
    return {
        'message': 'Evento criado com sucesso',
        'evento': serializar_evento(evento),
    }, 201


def listar_eventos(grupo_id: int) -> tuple[dict, int]:
    eventos = (
        Evento.query
        .filter_by(grupo_id=grupo_id, is_active=True)
        .order_by(Evento.data_evento.desc(), Evento.horario.desc())
        .all()
    )
    return {'eventos': [serializar_evento(e) for e in eventos]}, 200


def obter_evento(grupo_id: int, evento_id: int) -> tuple[dict, int]:
    evento = Evento.query.filter_by(id=evento_id, grupo_id=grupo_id).first()
    if not evento:
        return {'error': 'Evento nao encontrado'}, 404
    return {'evento': serializar_evento(evento)}, 200


def editar_evento(grupo_id: int, evento_id: int, dados: dict) -> tuple[dict, int]:
    evento = Evento.query.filter_by(id=evento_id, grupo_id=grupo_id).first()
    if not evento:
        return {'error': 'Evento nao encontrado'}, 404

    if evento.cancelado_em:
        return {'error': 'Evento cancelado nao pode ser editado'}, 400

    if 'nome' in dados:
        nome = (dados['nome'] or '').strip()
        if len(nome) < 3 or len(nome) > 100:
            return {'error': 'Nome deve ter entre 3 e 100 caracteres'}, 400
        evento.nome = nome

    if 'data_evento' in dados:
        try:
            evento.data_evento = date.fromisoformat(dados['data_evento'])
        except (ValueError, TypeError):
            return {'error': 'Data invalida (formato: YYYY-MM-DD)'}, 400

    if 'horario' in dados:
        try:
            from datetime import time
            parts = dados['horario'].split(':')
            evento.horario = time(int(parts[0]), int(parts[1]))
        except (ValueError, IndexError, AttributeError):
            return {'error': 'Horario invalido (formato: HH:MM)'}, 400

    if 'local' in dados:
        local = (dados['local'] or '').strip()
        if not local or len(local) > 255:
            return {'error': 'Local e obrigatorio (max 255 caracteres)'}, 400
        evento.local = local

    if 'observacoes' in dados:
        evento.observacoes = (dados['observacoes'] or '').strip() or None

    db.session.commit()
    return {
        'message': 'Evento atualizado com sucesso',
        'evento': serializar_evento(evento),
    }, 200


def cancelar_evento(grupo_id: int, evento_id: int, dados: dict) -> tuple[dict, int]:
    evento = Evento.query.filter_by(id=evento_id, grupo_id=grupo_id).first()
    if not evento:
        return {'error': 'Evento nao encontrado'}, 404

    if evento.cancelado_em:
        return {'error': 'Evento ja esta cancelado'}, 400

    evento.cancelado_em = datetime.now(timezone.utc)
    evento.motivo_cancelamento = (dados.get('motivo') or '').strip() or None
    evento.status_confirmacoes = 'encerrado'

    db.session.commit()
    return {
        'message': 'Evento cancelado',
        'evento': serializar_evento(evento),
    }, 200


def encerrar_confirmacoes(grupo_id: int, evento_id: int) -> tuple[dict, int]:
    evento = Evento.query.filter_by(id=evento_id, grupo_id=grupo_id).first()
    if not evento:
        return {'error': 'Evento nao encontrado'}, 404

    if evento.cancelado_em:
        return {'error': 'Evento cancelado'}, 400

    if evento.status_confirmacoes == 'encerrado':
        return {'error': 'Confirmacoes ja estao encerradas'}, 400

    evento.status_confirmacoes = 'encerrado'
    db.session.commit()
    return {
        'message': 'Confirmacoes encerradas',
        'evento': serializar_evento(evento),
    }, 200


def reabrir_confirmacoes(grupo_id: int, evento_id: int) -> tuple[dict, int]:
    evento = Evento.query.filter_by(id=evento_id, grupo_id=grupo_id).first()
    if not evento:
        return {'error': 'Evento nao encontrado'}, 404

    if evento.cancelado_em:
        return {'error': 'Evento cancelado'}, 400

    if evento.status_confirmacoes == 'aberto':
        return {'error': 'Confirmacoes ja estao abertas'}, 400

    evento.status_confirmacoes = 'aberto'
    db.session.commit()
    return {
        'message': 'Confirmacoes reabertas',
        'evento': serializar_evento(evento),
    }, 200


def responder_presenca(grupo_id: int, evento_id: int, user_id: int, dados: dict) -> tuple[dict, int]:
    evento = Evento.query.filter_by(id=evento_id, grupo_id=grupo_id).first()
    if not evento:
        return {'error': 'Evento nao encontrado'}, 404

    if evento.cancelado_em:
        return {'error': 'Evento cancelado'}, 400

    if evento.status_confirmacoes != 'aberto':
        return {'error': 'Confirmacoes encerradas para este evento'}, 400

    resposta = (dados.get('resposta') or '').strip()
    if resposta not in ('confirmado', 'nao_vou', 'talvez'):
        return {'error': 'Resposta invalida. Use: confirmado, nao_vou ou talvez'}, 400

    participante = EventoParticipante.query.filter_by(
        evento_id=evento_id, usuario_id=user_id
    ).first()

    if participante:
        participante.resposta = resposta
    else:
        participante = EventoParticipante(
            evento_id=evento_id, usuario_id=user_id, resposta=resposta,
        )
        db.session.add(participante)

    db.session.commit()
    return {
        'message': 'Presenca registrada',
        'resposta': resposta,
    }, 200


def listar_participantes(grupo_id: int, evento_id: int) -> tuple[dict, int]:
    evento = Evento.query.filter_by(id=evento_id, grupo_id=grupo_id).first()
    if not evento:
        return {'error': 'Evento nao encontrado'}, 404

    resultados = (
        db.session.query(EventoParticipante, Usuario, PerfilJogador)
        .join(Usuario, EventoParticipante.usuario_id == Usuario.id)
        .outerjoin(PerfilJogador, Usuario.id == PerfilJogador.usuario_id)
        .filter(EventoParticipante.evento_id == evento_id)
        .all()
    )

    confirmados = []
    nao_vou = []
    talvez = []

    for p, u, perfil in resultados:
        item = {
            'usuario_id': u.id,
            'nome': u.nome,
            'apelido': u.apelido,
            'foto_url': perfil.foto_url if perfil else None,
            'posicao_principal': perfil.posicao_principal if perfil else None,
            'resposta': p.resposta,
            'updated_at': p.updated_at.isoformat() if p.updated_at else None,
        }
        if p.resposta == 'confirmado':
            confirmados.append(item)
        elif p.resposta == 'nao_vou':
            nao_vou.append(item)
        else:
            talvez.append(item)

    return {
        'confirmados': confirmados,
        'nao_vou': nao_vou,
        'talvez': talvez,
        'total_confirmados': len(confirmados),
        'total_nao_vou': len(nao_vou),
        'total_talvez': len(talvez),
        'total': len(resultados),
    }, 200
