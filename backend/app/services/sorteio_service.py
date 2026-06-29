import random
from datetime import datetime, timezone

from app.database import db
from app.models.evento import Evento, EventoParticipante
from app.models.sorteio import Sorteio, Time, TimeJogador
from app.models.grupo import AvaliacaoJogador
from app.models.usuario import PerfilJogador
from app.models.notificacao import Notificacao
from app.models.grupo import GrupoMembro


def serializar_sorteio(sorteio: Sorteio) -> dict:
    times = []
    for t in sorteio.times:
        jogadores = []
        for j in t.jogadores:
            jogadores.append({
                'usuario_id': j.usuario_id,
                'posicao': j.posicao,
                'estrelas': j.estrelas,
                'eh_goleiro': j.eh_goleiro,
            })
        times.append({
            'id': t.id,
            'nome': t.nome,
            'ordem': t.ordem,
            'jogadores': jogadores,
            'total_jogadores': len(jogadores),
            'total_estrelas': sum(j.estrelas for j in t.jogadores),
        })
    return {
        'id': sorteio.id,
        'evento_id': sorteio.evento_id,
        'modalidade': sorteio.modalidade,
        'qtd_times': sorteio.qtd_times,
        'max_jogadores_time': sorteio.max_jogadores_time,
        'qtd_goleiros_time': sorteio.qtd_goleiros_time,
        'status': sorteio.status,
        'created_at': sorteio.created_at.isoformat() if sorteio.created_at else None,
        'confirmado_em': sorteio.confirmado_em.isoformat() if sorteio.confirmado_em else None,
        'times': times,
    }


def criar_sorteio(grupo_id: int, evento_id: int, dados: dict) -> tuple[dict, int]:
    evento = Evento.query.filter_by(id=evento_id, grupo_id=grupo_id).first()
    if not evento:
        return {'error': 'Evento nao encontrado'}, 404

    if evento.cancelado_em:
        return {'error': 'Evento cancelado'}, 400

    if evento.status_confirmacoes != 'encerrado':
        return {'error': 'Encerre as confirmacoes antes de sortear'}, 400

    existente = Sorteio.query.filter_by(evento_id=evento_id).first()
    if existente and existente.status == 'confirmado':
        return {'error': 'Este evento ja possui um sorteio confirmado'}, 409

    modalidade = (dados.get('modalidade') or '').strip()
    if modalidade not in ('aleatorio', 'balanceado'):
        return {'error': 'Modalidade deve ser aleatorio ou balanceado'}, 400

    qtd_times = dados.get('qtd_times')
    if not isinstance(qtd_times, int) or qtd_times < 2:
        return {'error': 'Quantidade de times deve ser pelo menos 2'}, 400

    nomes_times = dados.get('nomes_times') or [f'Time {i+1}' for i in range(qtd_times)]
    if len(nomes_times) != qtd_times:
        return {'error': 'Quantidade de nomes nao corresponde a quantidade de times'}, 400

    max_jogadores_time = dados.get('max_jogadores_time')
    qtd_goleiros_time = dados.get('qtd_goleiros_time')

    confirmados = EventoParticipante.query.filter_by(
        evento_id=evento_id, resposta='confirmado'
    ).all()

    if len(confirmados) < qtd_times:
        return {'error': f'Minimo de {qtd_times} jogadores confirmados para {qtd_times} times'}, 400

    jogadores = []
    for p in confirmados:
        perfil = PerfilJogador.query.filter_by(usuario_id=p.usuario_id).first()
        avaliacao = AvaliacaoJogador.query.filter_by(
            grupo_id=grupo_id, usuario_id=p.usuario_id
        ).first()
        jogadores.append({
            'usuario_id': p.usuario_id,
            'posicao': perfil.posicao_principal if perfil else 'Meio-campo',
            'estrelas': avaliacao.estrelas if avaliacao else 3,
            'eh_goleiro': perfil.posicao_principal == 'Goleiro' if perfil else False,
        })

    if modalidade == 'aleatorio':
        times_resultado = _sortear_aleatorio(jogadores, qtd_times)
    else:
        times_resultado = _sortear_balanceado(jogadores, qtd_times)

    if existente:
        db.session.delete(existente)
        db.session.flush()

    sorteio = Sorteio(
        evento_id=evento_id, modalidade=modalidade, qtd_times=qtd_times,
        max_jogadores_time=max_jogadores_time, qtd_goleiros_time=qtd_goleiros_time,
        status='realizado',
    )
    db.session.add(sorteio)
    db.session.flush()

    for i, jogadores_time in enumerate(times_resultado):
        time = Time(
            sorteio_id=sorteio.id, nome=nomes_times[i], ordem=i + 1,
        )
        db.session.add(time)
        db.session.flush()

        for j in jogadores_time:
            db.session.add(TimeJogador(
                time_id=time.id, usuario_id=j['usuario_id'],
                posicao=j['posicao'], estrelas=j['estrelas'],
                eh_goleiro=j['eh_goleiro'],
            ))

    db.session.commit()
    return {
        'message': 'Sorteio realizado com sucesso',
        'sorteio': serializar_sorteio(sorteio),
    }, 201


def _sortear_aleatorio(jogadores: list, qtd_times: int) -> list[list]:
    random.shuffle(jogadores)
    times = [[] for _ in range(qtd_times)]
    for i, j in enumerate(jogadores):
        times[i % qtd_times].append(j)
    return times


def _sortear_balanceado(jogadores: list, qtd_times: int) -> list[list]:
    goleiros = [j for j in jogadores if j['eh_goleiro']]
    linha = [j for j in jogadores if not j['eh_goleiro']]

    times = [[] for _ in range(qtd_times)]

    random.shuffle(goleiros)
    for i, g in enumerate(goleiros):
        times[i % qtd_times].append(g)

    linha.sort(key=lambda j: j['estrelas'], reverse=True)

    direcao = 1
    idx = 0
    for j in linha:
        times[idx].append(j)
        idx += direcao
        if idx >= qtd_times:
            direcao = -1
            idx = qtd_times - 1
        elif idx < 0:
            direcao = 1
            idx = 0

    return times


def obter_sorteio(grupo_id: int, evento_id: int) -> tuple[dict, int]:
    evento = Evento.query.filter_by(id=evento_id, grupo_id=grupo_id).first()
    if not evento:
        return {'error': 'Evento nao encontrado'}, 404

    sorteio = Sorteio.query.filter_by(evento_id=evento_id).first()
    if not sorteio:
        return {'error': 'Nenhum sorteio realizado para este evento'}, 404

    return {'sorteio': serializar_sorteio(sorteio)}, 200


def confirmar_sorteio(grupo_id: int, evento_id: int) -> tuple[dict, int]:
    evento = Evento.query.filter_by(id=evento_id, grupo_id=grupo_id).first()
    if not evento:
        return {'error': 'Evento nao encontrado'}, 404

    sorteio = Sorteio.query.filter_by(evento_id=evento_id).first()
    if not sorteio:
        return {'error': 'Nenhum sorteio realizado'}, 404

    if sorteio.status == 'confirmado':
        return {'error': 'Sorteio ja confirmado'}, 409

    if sorteio.status != 'realizado':
        return {'error': 'Sorteio precisa ser realizado antes de confirmar'}, 400

    sorteio.status = 'confirmado'
    sorteio.confirmado_em = datetime.now(timezone.utc)

    membros = GrupoMembro.query.filter_by(grupo_id=grupo_id, status='aprovado').all()
    for m in membros:
        db.session.add(Notificacao(
            usuario_id=m.usuario_id, tipo='sorteio_finalizado',
            titulo=f'Sorteio confirmado para {evento.nome}',
            referencia_tipo='evento', referencia_id=evento_id,
        ))

    db.session.commit()
    return {
        'message': 'Sorteio confirmado',
        'sorteio': serializar_sorteio(sorteio),
    }, 200
