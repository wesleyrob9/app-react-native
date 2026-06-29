from app.database import db
from sqlalchemy import func, CheckConstraint

POSICOES_VALIDAS = (
    'Goleiro', 'Zagueiro', 'Lateral', 'Volante',
    'Meio-campo', 'Meia-atacante', 'Atacante'
)


class Usuario(db.Model):
    __tablename__ = 'usuarios'

    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100), nullable=False)
    apelido = db.Column(db.String(50), nullable=True)
    email = db.Column(db.String(150), unique=True, nullable=False, index=True)
    username = db.Column(db.String(50), unique=True, nullable=False, index=True)
    senha_hash = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), server_default=func.now())
    updated_at = db.Column(db.DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    is_active = db.Column(db.Boolean, default=True, server_default='true')

    perfil = db.relationship('PerfilJogador', back_populates='usuario', uselist=False, cascade='all, delete-orphan')
    grupo_membros = db.relationship('GrupoMembro', back_populates='usuario', cascade='all, delete-orphan')
    evento_participacoes = db.relationship('EventoParticipante', back_populates='usuario', cascade='all, delete-orphan')
    notificacoes = db.relationship('Notificacao', back_populates='usuario', cascade='all, delete-orphan')
    password_reset_tokens = db.relationship('PasswordResetToken', back_populates='usuario', cascade='all, delete-orphan')


class PerfilJogador(db.Model):
    __tablename__ = 'perfis_jogador'

    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), primary_key=True)
    foto_url = db.Column(db.String(255), nullable=True)
    avatar = db.Column(db.String(50), nullable=True)
    data_nascimento = db.Column(db.Date, nullable=True)
    posicao_principal = db.Column(db.String(20), nullable=False)
    posicao_secundaria = db.Column(db.String(20), nullable=True)

    usuario = db.relationship('Usuario', back_populates='perfil')

    __table_args__ = (
        CheckConstraint(
            f"posicao_principal IN {POSICOES_VALIDAS}",
            name='ck_perfis_posicao_principal'
        ),
        CheckConstraint(
            f"posicao_secundaria IS NULL OR posicao_secundaria IN {POSICOES_VALIDAS}",
            name='ck_perfis_posicao_secundaria'
        ),
    )
