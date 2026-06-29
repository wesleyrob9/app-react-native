from datetime import datetime, timedelta, timezone

import jwt
from flask import current_app


def gerar_access_token(user_id: int) -> str:
    payload = {
        'sub': str(user_id),
        'type': 'access',
        'iat': datetime.now(timezone.utc),
        'exp': datetime.now(timezone.utc) + timedelta(
            seconds=current_app.config['JWT_ACCESS_TOKEN_EXPIRES']
        ),
    }
    return jwt.encode(payload, current_app.config['JWT_SECRET_KEY'], algorithm='HS256')


def gerar_refresh_token(user_id: int) -> str:
    payload = {
        'sub': str(user_id),
        'type': 'refresh',
        'iat': datetime.now(timezone.utc),
        'exp': datetime.now(timezone.utc) + timedelta(
            seconds=current_app.config['JWT_REFRESH_TOKEN_EXPIRES']
        ),
    }
    return jwt.encode(payload, current_app.config['JWT_REFRESH_SECRET_KEY'], algorithm='HS256')


def decodificar_access_token(token: str) -> dict | None:
    try:
        payload = jwt.decode(token, current_app.config['JWT_SECRET_KEY'], algorithms=['HS256'])
        if payload.get('type') != 'access':
            return None
        payload['sub'] = int(payload['sub'])
        return payload
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
        return None


def decodificar_refresh_token(token: str) -> dict | None:
    try:
        payload = jwt.decode(token, current_app.config['JWT_REFRESH_SECRET_KEY'], algorithms=['HS256'])
        if payload.get('type') != 'refresh':
            return None
        payload['sub'] = int(payload['sub'])
        return payload
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
        return None
