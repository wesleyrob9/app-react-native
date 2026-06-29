from app.database import db
from app.models.grupo import AvaliacaoJogador, GrupoMembro
from app.models.historico_avaliacao import HistoricoAvaliacao
from app.models.usuario import Usuario, PerfilJogador


def avaliar_jogador(grupo_id: int, usuario_id: int, admin_id: int, dados: dict) -> tuple[dict, int]:
    estrelas = dados.get('estrelas')

    if estrelas is None or not isinstance(estrelas, int) or estrelas < 1 or estrelas > 5:
        return {'error': 'Estrelas deve ser um numero entre 1 e 5'}, 400

    membro = GrupoMembro.query.filter_by(
        grupo_id=grupo_id, usuario_id=usuario_id, status='aprovado'
    ).first()
    if not membro:
        return {'error': 'Jogador nao e membro aprovado deste grupo'}, 404

    avaliacao = AvaliacaoJogador.query.filter_by(
        grupo_id=grupo_id, usuario_id=usuario_id
    ).first()

    avaliacao_anterior = avaliacao.estrelas if avaliacao else None

    if avaliacao:
        avaliacao.estrelas = estrelas
    else:
        avaliacao = AvaliacaoJogador(
            grupo_id=grupo_id, usuario_id=usuario_id, estrelas=estrelas,
        )
        db.session.add(avaliacao)

    historico = HistoricoAvaliacao(
        grupo_id=grupo_id, usuario_id=usuario_id, admin_id=admin_id,
        avaliacao_anterior=avaliacao_anterior, avaliacao_nova=estrelas,
    )
    db.session.add(historico)

    db.session.commit()
    return {
        'message': 'Avaliacao registrada',
        'avaliacao': {
            'grupo_id': grupo_id,
            'usuario_id': usuario_id,
            'estrelas': estrelas,
            'anterior': avaliacao_anterior,
        },
    }, 200


def obter_avaliacao(grupo_id: int, usuario_id: int) -> tuple[dict, int]:
    avaliacao = AvaliacaoJogador.query.filter_by(
        grupo_id=grupo_id, usuario_id=usuario_id
    ).first()

    return {
        'avaliacao': {
            'grupo_id': grupo_id,
            'usuario_id': usuario_id,
            'estrelas': avaliacao.estrelas if avaliacao else None,
        },
    }, 200


def listar_avaliacoes(grupo_id: int) -> tuple[dict, int]:
    resultados = (
        db.session.query(GrupoMembro, Usuario, PerfilJogador, AvaliacaoJogador)
        .join(Usuario, GrupoMembro.usuario_id == Usuario.id)
        .outerjoin(PerfilJogador, Usuario.id == PerfilJogador.usuario_id)
        .outerjoin(AvaliacaoJogador, db.and_(
            AvaliacaoJogador.grupo_id == GrupoMembro.grupo_id,
            AvaliacaoJogador.usuario_id == GrupoMembro.usuario_id,
        ))
        .filter(GrupoMembro.grupo_id == grupo_id, GrupoMembro.status == 'aprovado')
        .all()
    )

    avaliacoes = []
    for m, u, p, a in resultados:
        avaliacoes.append({
            'usuario_id': u.id,
            'nome': u.nome,
            'apelido': u.apelido,
            'posicao_principal': p.posicao_principal if p else None,
            'estrelas': a.estrelas if a else None,
        })

    return {'avaliacoes': avaliacoes}, 200


def historico_jogador(grupo_id: int, usuario_id: int) -> tuple[dict, int]:
    registros = (
        HistoricoAvaliacao.query
        .filter_by(grupo_id=grupo_id, usuario_id=usuario_id)
        .order_by(HistoricoAvaliacao.created_at.desc())
        .all()
    )

    historico = []
    for h in registros:
        admin = db.session.get(Usuario, h.admin_id) if h.admin_id else None
        historico.append({
            'avaliacao_anterior': h.avaliacao_anterior,
            'avaliacao_nova': h.avaliacao_nova,
            'admin_nome': admin.nome if admin else None,
            'created_at': h.created_at.isoformat() if h.created_at else None,
        })

    return {'historico': historico}, 200
