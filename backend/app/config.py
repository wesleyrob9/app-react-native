import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent.parent / '.env')


class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key-trocar-em-producao')

    SQLALCHEMY_DATABASE_URI = os.environ.get(
        'DATABASE_URL',
        'postgresql://usuario:senha@localhost:5432/futebol_app'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_size': 10,
        'pool_recycle': 300,
        'max_overflow': 5,
    }

    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'jwt-secret-trocar')
    JWT_REFRESH_SECRET_KEY = os.environ.get('JWT_REFRESH_SECRET_KEY', 'jwt-refresh-secret-trocar')
    JWT_ACCESS_TOKEN_EXPIRES = 15 * 60
    JWT_REFRESH_TOKEN_EXPIRES = 30 * 24 * 3600

    BCRYPT_COST_FACTOR = 12

    RATELIMIT_DEFAULT = "60/minute"
