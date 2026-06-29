from app.database import db
from app.models.notificacao import Notificacao


def listar_notificacoes(user_id: int, apenas_nao_lidas: bool = False) -> tuple[dict, int]:
    query = Notificacao.query.filter_by(usuario_id=user_id)

    if apenas_nao_lidas:
        query = query.filter_by(lida=False)

    notificacoes = query.order_by(Notificacao.created_at.desc()).all()

    return {
        'notificacoes': [_serializar(n) for n in notificacoes],
        'total': len(notificacoes),
        'nao_lidas': sum(1 for n in notificacoes if not n.lida) if not apenas_nao_lidas
        else len(notificacoes),
    }, 200


def contar_nao_lidas(user_id: int) -> tuple[dict, int]:
    total = Notificacao.query.filter_by(usuario_id=user_id, lida=False).count()
    return {'nao_lidas': total}, 200


def marcar_como_lida(user_id: int, notificacao_id: int) -> tuple[dict, int]:
    notificacao = Notificacao.query.filter_by(id=notificacao_id, usuario_id=user_id).first()
    if not notificacao:
        return {'error': 'Notificacao nao encontrada'}, 404

    notificacao.lida = True
    db.session.commit()
    return {'message': 'Notificacao marcada como lida'}, 200


def marcar_todas_como_lidas(user_id: int) -> tuple[dict, int]:
    atualizadas = Notificacao.query.filter_by(
        usuario_id=user_id, lida=False
    ).update({'lida': True})
    db.session.commit()
    return {'message': f'{atualizadas} notificacoes marcadas como lidas'}, 200


def _serializar(n: Notificacao) -> dict:
    return {
        'id': n.id,
        'tipo': n.tipo,
        'titulo': n.titulo,
        'mensagem': n.mensagem,
        'referencia_tipo': n.referencia_tipo,
        'referencia_id': n.referencia_id,
        'lida': n.lida,
        'created_at': n.created_at.isoformat() if n.created_at else None,
    }
