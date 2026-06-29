from functools import wraps

from flask import g, jsonify, request

from app.utils.jwt_utils import decodificar_access_token


def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '')

        if not auth_header.startswith('Bearer '):
            return jsonify({'error': 'Token invalido ou expirado'}), 401

        token = auth_header[7:]
        payload = decodificar_access_token(token)

        if payload is None:
            return jsonify({'error': 'Token invalido ou expirado'}), 401

        g.user_id = payload['sub']
        return f(*args, **kwargs)

    return decorated


def membro_required(f):
    @wraps(f)
    @token_required
    def decorated(*args, **kwargs):
        from app.models.grupo import GrupoMembro
        grupo_id = kwargs.get('grupo_id')
        membro = GrupoMembro.query.filter_by(
            grupo_id=grupo_id, usuario_id=g.user_id, status='aprovado'
        ).first()
        if not membro:
            return jsonify({'error': 'Voce nao e membro deste grupo'}), 403
        g.membro = membro
        return f(*args, **kwargs)
    return decorated


def admin_required(f):
    @wraps(f)
    @token_required
    def decorated(*args, **kwargs):
        from app.models.grupo import GrupoMembro
        grupo_id = kwargs.get('grupo_id')
        membro = GrupoMembro.query.filter_by(
            grupo_id=grupo_id, usuario_id=g.user_id, status='aprovado'
        ).first()
        if not membro:
            return jsonify({'error': 'Voce nao e membro deste grupo'}), 403
        if membro.papel != 'admin':
            return jsonify({'error': 'Apenas administradores podem realizar esta acao'}), 403
        g.membro = membro
        return f(*args, **kwargs)
    return decorated
