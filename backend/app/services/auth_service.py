import re
import secrets
from datetime import datetime, timedelta, timezone

import bcrypt
from flask import current_app

from app.database import db
from app.models.usuario import Usuario, PerfilJogador, POSICOES_VALIDAS
from app.models.password_reset import PasswordResetToken
from app.utils.jwt_utils import gerar_access_token, gerar_refresh_token


def validar_senha(senha: str) -> str | None:
    if len(senha) < 8:
        return 'Senha deve ter no minimo 8 caracteres'
    if not re.search(r'[A-Z]', senha):
        return 'Senha deve conter pelo menos uma letra maiuscula'
    if not re.search(r'[0-9]', senha):
        return 'Senha deve conter pelo menos um numero'
    if not re.search(r'[@#$%^&+=!]', senha):
        return 'Senha deve conter pelo menos um caractere especial (@#$%^&+=!)'
    return None


def hash_senha(senha: str) -> str:
    cost = current_app.config.get('BCRYPT_COST_FACTOR', 12)
    salt = bcrypt.gensalt(rounds=cost)
    return bcrypt.hashpw(senha.encode('utf-8'), salt).decode('utf-8')


def verificar_senha(senha: str, senha_hash: str) -> bool:
    return bcrypt.checkpw(senha.encode('utf-8'), senha_hash.encode('utf-8'))


def serializar_usuario(usuario: Usuario, incluir_perfil: bool = False) -> dict:
    data = {
        'id': usuario.id,
        'nome': usuario.nome,
        'apelido': usuario.apelido,
        'email': usuario.email,
        'username': usuario.username,
        'created_at': usuario.created_at.isoformat() if usuario.created_at else None,
    }
    if incluir_perfil and usuario.perfil:
        data['perfil'] = {
            'foto_url': usuario.perfil.foto_url,
            'avatar': usuario.perfil.avatar,
            'data_nascimento': usuario.perfil.data_nascimento.isoformat() if usuario.perfil.data_nascimento else None,
            'posicao_principal': usuario.perfil.posicao_principal,
            'posicao_secundaria': usuario.perfil.posicao_secundaria,
        }
    return data


def registrar_usuario(dados: dict) -> tuple[dict, int]:
    nome = (dados.get('nome') or '').strip()
    apelido = (dados.get('apelido') or '').strip() or None
    email = (dados.get('email') or '').strip().lower()
    username = (dados.get('username') or '').strip().lower()
    senha = dados.get('senha') or ''
    posicao_principal = (dados.get('posicao_principal') or '').strip()
    posicao_secundaria = (dados.get('posicao_secundaria') or '').strip() or None

    if not nome or len(nome) < 3 or len(nome) > 100:
        return {'error': 'Nome deve ter entre 3 e 100 caracteres'}, 400

    if apelido and len(apelido) > 50:
        return {'error': 'Apelido deve ter no maximo 50 caracteres'}, 400

    if not email or not re.match(r'^[^@\s]+@[^@\s]+\.[^@\s]+$', email):
        return {'error': 'E-mail invalido'}, 400

    if not username or len(username) < 3 or len(username) > 50:
        return {'error': 'Username deve ter entre 3 e 50 caracteres'}, 400

    if not re.match(r'^[a-z0-9_]+$', username):
        return {'error': 'Username deve conter apenas letras, numeros e underscore'}, 400

    erro_senha = validar_senha(senha)
    if erro_senha:
        return {'error': erro_senha}, 400

    if posicao_principal not in POSICOES_VALIDAS:
        return {'error': 'Posicao principal invalida'}, 400

    if posicao_secundaria and posicao_secundaria not in POSICOES_VALIDAS:
        return {'error': 'Posicao secundaria invalida'}, 400

    if Usuario.query.filter_by(email=email).first():
        return {'error': 'E-mail ja cadastrado'}, 409

    if Usuario.query.filter_by(username=username).first():
        return {'error': 'Username ja esta em uso'}, 409

    usuario = Usuario(
        nome=nome,
        apelido=apelido,
        email=email,
        username=username,
        senha_hash=hash_senha(senha),
    )
    db.session.add(usuario)
    db.session.flush()

    perfil = PerfilJogador(
        usuario_id=usuario.id,
        posicao_principal=posicao_principal,
        posicao_secundaria=posicao_secundaria,
    )
    db.session.add(perfil)
    db.session.commit()

    return {
        'message': 'Usuario cadastrado com sucesso',
        'usuario': serializar_usuario(usuario),
        'access_token': gerar_access_token(usuario.id),
        'refresh_token': gerar_refresh_token(usuario.id),
    }, 201


def login_usuario(dados: dict) -> tuple[dict, int]:
    login = (dados.get('login') or '').strip().lower()
    senha = dados.get('senha') or ''

    if not login:
        return {'error': 'Informe seu usuario ou e-mail'}, 400

    if not senha:
        return {'error': 'Informe sua senha'}, 400

    if '@' in login:
        usuario = Usuario.query.filter_by(email=login).first()
    else:
        usuario = Usuario.query.filter_by(username=login).first()

    if not usuario or not verificar_senha(senha, usuario.senha_hash):
        return {'error': 'Usuario ou senha incorretos'}, 401

    if not usuario.is_active:
        return {'error': 'Conta desativada. Entre em contato com o suporte'}, 403

    return {
        'message': 'Login realizado com sucesso',
        'usuario': serializar_usuario(usuario, incluir_perfil=True),
        'access_token': gerar_access_token(usuario.id),
        'refresh_token': gerar_refresh_token(usuario.id),
    }, 200


def refresh_access_token(dados: dict) -> tuple[dict, int]:
    from app.utils.jwt_utils import decodificar_refresh_token

    refresh_token = dados.get('refresh_token') or ''

    if not refresh_token:
        return {'error': 'Token invalido ou expirado'}, 401

    payload = decodificar_refresh_token(refresh_token)
    if payload is None:
        return {'error': 'Token invalido ou expirado'}, 401

    usuario = db.session.get(Usuario, payload['sub'])

    if not usuario:
        return {'error': 'Token invalido ou expirado'}, 401

    if not usuario.is_active:
        return {'error': 'Conta desativada'}, 403

    return {
        'access_token': gerar_access_token(usuario.id),
    }, 200


def obter_perfil(user_id: int) -> tuple[dict, int]:
    usuario = db.session.get(Usuario, user_id)

    if not usuario or not usuario.is_active:
        return {'error': 'Usuario nao encontrado'}, 404

    return {
        'usuario': serializar_usuario(usuario, incluir_perfil=True),
    }, 200


def atualizar_perfil(user_id: int, dados: dict) -> tuple[dict, int]:
    usuario = db.session.get(Usuario, user_id)

    if not usuario or not usuario.is_active:
        return {'error': 'Usuario nao encontrado'}, 404

    if 'nome' in dados:
        nome = (dados['nome'] or '').strip()
        if len(nome) < 3 or len(nome) > 100:
            return {'error': 'Nome deve ter entre 3 e 100 caracteres'}, 400
        usuario.nome = nome

    if 'apelido' in dados:
        apelido = (dados['apelido'] or '').strip() or None
        if apelido and len(apelido) > 50:
            return {'error': 'Apelido deve ter no maximo 50 caracteres'}, 400
        usuario.apelido = apelido

    perfil = usuario.perfil
    if not perfil:
        return {'error': 'Perfil nao encontrado'}, 404

    if 'posicao_principal' in dados:
        posicao = (dados['posicao_principal'] or '').strip()
        if posicao not in POSICOES_VALIDAS:
            return {'error': 'Posicao principal invalida'}, 400
        perfil.posicao_principal = posicao

    if 'posicao_secundaria' in dados:
        posicao = (dados['posicao_secundaria'] or '').strip() or None
        if posicao and posicao not in POSICOES_VALIDAS:
            return {'error': 'Posicao secundaria invalida'}, 400
        perfil.posicao_secundaria = posicao

    if 'foto_url' in dados:
        perfil.foto_url = dados['foto_url']

    if 'avatar' in dados:
        perfil.avatar = dados['avatar']

    if 'data_nascimento' in dados:
        perfil.data_nascimento = dados['data_nascimento']

    db.session.commit()

    return {
        'message': 'Perfil atualizado com sucesso',
        'usuario': serializar_usuario(usuario, incluir_perfil=True),
    }, 200


def alterar_senha(user_id: int, dados: dict) -> tuple[dict, int]:
    senha_atual = dados.get('senha_atual') or ''
    nova_senha = dados.get('nova_senha') or ''

    if not senha_atual:
        return {'error': 'Informe a senha atual'}, 400

    if not nova_senha:
        return {'error': 'Informe a nova senha'}, 400

    usuario = db.session.get(Usuario, user_id)

    if not usuario or not usuario.is_active:
        return {'error': 'Usuario nao encontrado'}, 404

    if not verificar_senha(senha_atual, usuario.senha_hash):
        return {'error': 'Senha atual incorreta'}, 401

    if senha_atual == nova_senha:
        return {'error': 'A nova senha deve ser diferente da atual'}, 400

    erro_senha = validar_senha(nova_senha)
    if erro_senha:
        return {'error': erro_senha}, 400

    usuario.senha_hash = hash_senha(nova_senha)
    db.session.commit()

    return {'message': 'Senha alterada com sucesso'}, 200


def solicitar_reset_senha(dados: dict) -> tuple[dict, int]:
    email = (dados.get('email') or '').strip().lower()
    mensagem = 'Se o e-mail estiver cadastrado, voce recebera as instrucoes de recuperacao'

    if not email:
        return {'message': mensagem}, 200

    usuario = Usuario.query.filter_by(email=email, is_active=True).first()

    if usuario:
        PasswordResetToken.query.filter_by(
            usuario_id=usuario.id, used=False
        ).update({'used': True})

        token = PasswordResetToken(
            usuario_id=usuario.id,
            token=secrets.token_urlsafe(32),
            expires_at=datetime.now(timezone.utc) + timedelta(hours=1),
        )
        db.session.add(token)
        db.session.commit()

        # TODO: Enviar email com o token.token para o usuario
        # Por enquanto, o token e gerado e salvo no banco

    return {'message': mensagem}, 200


def redefinir_senha(dados: dict) -> tuple[dict, int]:
    token_str = (dados.get('token') or '').strip()
    nova_senha = dados.get('nova_senha') or ''

    if not token_str:
        return {'error': 'Token invalido ou expirado'}, 401

    token = PasswordResetToken.query.filter_by(
        token=token_str, used=False
    ).first()

    if not token or token.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
        return {'error': 'Token invalido ou expirado'}, 401

    erro_senha = validar_senha(nova_senha)
    if erro_senha:
        return {'error': erro_senha}, 400

    usuario = db.session.get(Usuario, token.usuario_id)
    usuario.senha_hash = hash_senha(nova_senha)
    token.used = True
    db.session.commit()

    return {'message': 'Senha redefinida com sucesso'}, 200
