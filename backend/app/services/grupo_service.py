import secrets
import string

from sqlalchemy import func

from app.database import db
from app.models.grupo import Grupo, GrupoMembro, AvaliacaoJogador
from app.models.usuario import Usuario, PerfilJogador
from app.models.notificacao import Notificacao


def gerar_codigo_convite() -> str:
    chars = string.ascii_letters + string.digits
    while True:
        codigo = ''.join(secrets.choice(chars) for _ in range(8))
        if not Grupo.query.filter_by(codigo_convite=codigo).first():
            return codigo


def contar_membros(grupo_id: int) -> int:
    return GrupoMembro.query.filter_by(grupo_id=grupo_id, status='aprovado').count()


def contar_admins(grupo_id: int) -> int:
    return GrupoMembro.query.filter_by(grupo_id=grupo_id, papel='admin', status='aprovado').count()


def serializar_grupo(grupo: Grupo, papel: str = None, total: int = None) -> dict:
    data = {
        'id': grupo.id,
        'nome': grupo.nome,
        'descricao': grupo.descricao,
        'logo_url': grupo.logo_url,
        'cidade': grupo.cidade,
        'created_at': grupo.created_at.isoformat() if grupo.created_at else None,
        'total_membros': total if total is not None else contar_membros(grupo.id),
    }
    if papel:
        data['papel'] = papel
    if papel == 'admin':
        data['codigo_convite'] = grupo.codigo_convite
    return data


def notificar_admins(grupo_id: int, tipo: str, titulo: str, mensagem: str = None, excluir_uid: int = None):
    admins = GrupoMembro.query.filter_by(grupo_id=grupo_id, papel='admin', status='aprovado').all()
    for adm in admins:
        if adm.usuario_id == excluir_uid:
            continue
        db.session.add(Notificacao(
            usuario_id=adm.usuario_id, tipo=tipo, titulo=titulo,
            mensagem=mensagem, referencia_tipo='grupo', referencia_id=grupo_id,
        ))


def criar_grupo(user_id: int, dados: dict) -> tuple[dict, int]:
    nome = (dados.get('nome') or '').strip()
    descricao = (dados.get('descricao') or '').strip() or None
    logo_url = dados.get('logo_url')
    cidade = (dados.get('cidade') or '').strip() or None

    if not nome or len(nome) < 3 or len(nome) > 100:
        return {'error': 'Nome deve ter entre 3 e 100 caracteres'}, 400

    if cidade and len(cidade) > 100:
        return {'error': 'Cidade deve ter no maximo 100 caracteres'}, 400

    grupo = Grupo(
        nome=nome, descricao=descricao, logo_url=logo_url,
        cidade=cidade, codigo_convite=gerar_codigo_convite(),
    )
    db.session.add(grupo)
    db.session.flush()

    membro = GrupoMembro(
        grupo_id=grupo.id, usuario_id=user_id,
        papel='admin', status='aprovado',
    )
    db.session.add(membro)
    db.session.commit()

    return {
        'message': 'Grupo criado com sucesso',
        'grupo': serializar_grupo(grupo, papel='admin', total=1),
    }, 201


def listar_meus_grupos(user_id: int) -> tuple[dict, int]:
    membros = GrupoMembro.query.filter_by(usuario_id=user_id, status='aprovado').all()
    grupos = []
    for m in membros:
        grupo = db.session.get(Grupo, m.grupo_id)
        if grupo:
            g = serializar_grupo(grupo, papel=m.papel)
            del g['descricao']
            del g['created_at']
            grupos.append(g)
    return {'grupos': grupos}, 200


def obter_grupo(grupo_id: int, papel: str) -> tuple[dict, int]:
    grupo = db.session.get(Grupo, grupo_id)
    if not grupo:
        return {'error': 'Grupo nao encontrado'}, 404
    return {'grupo': serializar_grupo(grupo, papel=papel)}, 200


def editar_grupo(grupo_id: int, dados: dict) -> tuple[dict, int]:
    grupo = db.session.get(Grupo, grupo_id)
    if not grupo:
        return {'error': 'Grupo nao encontrado'}, 404

    if 'nome' in dados:
        nome = (dados['nome'] or '').strip()
        if len(nome) < 3 or len(nome) > 100:
            return {'error': 'Nome deve ter entre 3 e 100 caracteres'}, 400
        grupo.nome = nome

    if 'descricao' in dados:
        grupo.descricao = (dados['descricao'] or '').strip() or None

    if 'logo_url' in dados:
        grupo.logo_url = dados['logo_url']

    if 'cidade' in dados:
        cidade = (dados['cidade'] or '').strip() or None
        if cidade and len(cidade) > 100:
            return {'error': 'Cidade deve ter no maximo 100 caracteres'}, 400
        grupo.cidade = cidade

    if dados.get('regenerar_convite'):
        grupo.codigo_convite = gerar_codigo_convite()

    db.session.commit()
    return {
        'message': 'Grupo atualizado com sucesso',
        'grupo': serializar_grupo(grupo, papel='admin'),
    }, 200


def solicitar_entrada(user_id: int, dados: dict) -> tuple[dict, int]:
    codigo = (dados.get('codigo_convite') or '').strip()
    if not codigo:
        return {'error': 'Informe o codigo de convite'}, 400

    grupo = Grupo.query.filter_by(codigo_convite=codigo).first()
    if not grupo:
        return {'error': 'Codigo de convite invalido'}, 404

    existente = GrupoMembro.query.filter_by(grupo_id=grupo.id, usuario_id=user_id).first()
    if existente:
        if existente.status == 'aprovado':
            return {'error': 'Voce ja faz parte deste grupo'}, 409
        if existente.status == 'pendente':
            return {'error': 'Solicitacao ja enviada'}, 409
        if existente.status == 'rejeitado':
            existente.status = 'pendente'
            db.session.commit()
            notificar_admins(grupo.id, 'novo_evento',
                             f'Nova solicitacao de entrada no grupo {grupo.nome}')
            return {
                'message': 'Solicitacao reenviada com sucesso',
                'grupo': {'id': grupo.id, 'nome': grupo.nome},
            }, 201

    membro = GrupoMembro(
        grupo_id=grupo.id, usuario_id=user_id,
        papel='membro', status='pendente',
    )
    db.session.add(membro)

    usuario = db.session.get(Usuario, user_id)
    notificar_admins(grupo.id, 'novo_evento',
                     f'{usuario.nome} solicitou entrada no grupo {grupo.nome}')

    db.session.commit()
    return {
        'message': 'Solicitacao enviada com sucesso',
        'grupo': {'id': grupo.id, 'nome': grupo.nome},
    }, 201


def listar_membros(grupo_id: int) -> tuple[dict, int]:
    resultados = (
        db.session.query(
            GrupoMembro, Usuario, PerfilJogador, AvaliacaoJogador
        )
        .join(Usuario, GrupoMembro.usuario_id == Usuario.id)
        .outerjoin(PerfilJogador, Usuario.id == PerfilJogador.usuario_id)
        .outerjoin(AvaliacaoJogador, db.and_(
            AvaliacaoJogador.grupo_id == GrupoMembro.grupo_id,
            AvaliacaoJogador.usuario_id == GrupoMembro.usuario_id,
        ))
        .filter(GrupoMembro.grupo_id == grupo_id, GrupoMembro.status == 'aprovado')
        .all()
    )

    membros = []
    for m, u, p, a in resultados:
        membros.append({
            'usuario_id': u.id,
            'nome': u.nome,
            'apelido': u.apelido,
            'foto_url': p.foto_url if p else None,
            'posicao_principal': p.posicao_principal if p else None,
            'papel': m.papel,
            'estrelas': a.estrelas if a else None,
        })

    return {'membros': membros}, 200


def listar_pendentes(grupo_id: int) -> tuple[dict, int]:
    resultados = (
        db.session.query(GrupoMembro, Usuario, PerfilJogador)
        .join(Usuario, GrupoMembro.usuario_id == Usuario.id)
        .outerjoin(PerfilJogador, Usuario.id == PerfilJogador.usuario_id)
        .filter(GrupoMembro.grupo_id == grupo_id, GrupoMembro.status == 'pendente')
        .all()
    )

    pendentes = []
    for m, u, p in resultados:
        pendentes.append({
            'usuario_id': u.id,
            'nome': u.nome,
            'apelido': u.apelido,
            'posicao_principal': p.posicao_principal if p else None,
            'created_at': m.created_at.isoformat() if m.created_at else None,
        })

    return {'pendentes': pendentes}, 200


def aprovar_membro(grupo_id: int, usuario_id: int) -> tuple[dict, int]:
    membro = GrupoMembro.query.filter_by(grupo_id=grupo_id, usuario_id=usuario_id).first()
    if not membro:
        return {'error': 'Solicitacao nao encontrada'}, 404
    if membro.status == 'aprovado':
        return {'error': 'Membro ja esta aprovado'}, 409
    if membro.status != 'pendente':
        return {'error': 'Solicitacao nao esta pendente'}, 400

    membro.status = 'aprovado'

    grupo = db.session.get(Grupo, grupo_id)
    db.session.add(Notificacao(
        usuario_id=usuario_id, tipo='aprovacao_grupo',
        titulo=f'Voce foi aprovado no grupo {grupo.nome}',
        referencia_tipo='grupo', referencia_id=grupo_id,
    ))

    db.session.commit()
    return {'message': 'Membro aprovado com sucesso'}, 200


def rejeitar_membro(grupo_id: int, usuario_id: int) -> tuple[dict, int]:
    membro = GrupoMembro.query.filter_by(grupo_id=grupo_id, usuario_id=usuario_id).first()
    if not membro:
        return {'error': 'Solicitacao nao encontrada'}, 404
    if membro.status != 'pendente':
        return {'error': 'Solicitacao nao esta pendente'}, 400

    membro.status = 'rejeitado'

    grupo = db.session.get(Grupo, grupo_id)
    db.session.add(Notificacao(
        usuario_id=usuario_id, tipo='rejeicao_grupo',
        titulo=f'Sua solicitacao para o grupo {grupo.nome} foi rejeitada',
        referencia_tipo='grupo', referencia_id=grupo_id,
    ))

    db.session.commit()
    return {'message': 'Solicitacao rejeitada'}, 200


def promover_membro(grupo_id: int, usuario_id: int) -> tuple[dict, int]:
    membro = GrupoMembro.query.filter_by(grupo_id=grupo_id, usuario_id=usuario_id, status='aprovado').first()
    if not membro:
        return {'error': 'Membro nao encontrado'}, 404
    if membro.papel == 'admin':
        return {'error': 'Membro ja e administrador'}, 409

    membro.papel = 'admin'

    grupo = db.session.get(Grupo, grupo_id)
    db.session.add(Notificacao(
        usuario_id=usuario_id, tipo='promovido_admin',
        titulo=f'Voce foi promovido a administrador no grupo {grupo.nome}',
        referencia_tipo='grupo', referencia_id=grupo_id,
    ))

    db.session.commit()
    return {'message': 'Membro promovido a administrador'}, 200


def rebaixar_admin(grupo_id: int, usuario_id: int) -> tuple[dict, int]:
    membro = GrupoMembro.query.filter_by(grupo_id=grupo_id, usuario_id=usuario_id, status='aprovado').first()
    if not membro:
        return {'error': 'Membro nao encontrado'}, 404
    if membro.papel != 'admin':
        return {'error': 'Membro nao e administrador'}, 400

    if contar_admins(grupo_id) <= 1:
        return {'error': 'O grupo deve ter pelo menos um administrador'}, 400

    membro.papel = 'membro'
    db.session.commit()
    return {'message': 'Administrador rebaixado para membro'}, 200


def remover_membro(grupo_id: int, usuario_id: int, admin_id: int) -> tuple[dict, int]:
    if usuario_id == admin_id:
        return {'error': 'Use a opcao de sair do grupo para se remover'}, 400

    membro = GrupoMembro.query.filter_by(grupo_id=grupo_id, usuario_id=usuario_id).first()
    if not membro:
        return {'error': 'Membro nao encontrado'}, 404

    if membro.papel == 'admin' and contar_admins(grupo_id) <= 1:
        return {'error': 'O grupo deve ter pelo menos um administrador'}, 400

    grupo = db.session.get(Grupo, grupo_id)
    db.session.add(Notificacao(
        usuario_id=usuario_id, tipo='removido_grupo',
        titulo=f'Voce foi removido do grupo {grupo.nome}',
        referencia_tipo='grupo', referencia_id=grupo_id,
    ))

    db.session.delete(membro)
    db.session.commit()
    return {'message': 'Membro removido do grupo'}, 200


def sair_do_grupo(grupo_id: int, user_id: int) -> tuple[dict, int]:
    membro = GrupoMembro.query.filter_by(grupo_id=grupo_id, usuario_id=user_id, status='aprovado').first()
    if not membro:
        return {'error': 'Voce nao e membro deste grupo'}, 403

    if membro.papel == 'admin' and contar_admins(grupo_id) <= 1:
        return {'error': 'Voce e o unico administrador. Promova outro membro antes de sair'}, 400

    db.session.delete(membro)
    db.session.commit()
    return {'message': 'Voce saiu do grupo'}, 200
