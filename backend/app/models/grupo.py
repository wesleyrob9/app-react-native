from app.database import db
from sqlalchemy import func, CheckConstraint


class Grupo(db.Model):
    __tablename__ = 'grupos'

    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100), nullable=False)
    descricao = db.Column(db.Text, nullable=True)
    logo_url = db.Column(db.String(255), nullable=True)
    cidade = db.Column(db.String(100), nullable=True)
    codigo_convite = db.Column(db.String(20), unique=True, nullable=False, index=True)
    created_at = db.Column(db.DateTime(timezone=True), server_default=func.now())

    membros = db.relationship('GrupoMembro', back_populates='grupo', cascade='all, delete-orphan')
    eventos = db.relationship('Evento', back_populates='grupo', cascade='all, delete-orphan')
    avaliacoes = db.relationship('AvaliacaoJogador', back_populates='grupo', cascade='all, delete-orphan')
    historico_avaliacoes = db.relationship('HistoricoAvaliacao', back_populates='grupo', cascade='all, delete-orphan')


class GrupoMembro(db.Model):
    __tablename__ = 'grupo_membros'

    grupo_id = db.Column(db.Integer, db.ForeignKey('grupos.id', ondelete='CASCADE'), primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), primary_key=True, index=True)
    papel = db.Column(db.String(20), nullable=False, server_default='membro')
    status = db.Column(db.String(20), nullable=False, server_default='pendente')
    created_at = db.Column(db.DateTime(timezone=True), server_default=func.now())

    grupo = db.relationship('Grupo', back_populates='membros')
    usuario = db.relationship('Usuario', back_populates='grupo_membros')

    __table_args__ = (
        CheckConstraint("papel IN ('admin', 'membro')", name='ck_grupo_membros_papel'),
        CheckConstraint("status IN ('pendente', 'aprovado', 'rejeitado')", name='ck_grupo_membros_status'),
    )


class AvaliacaoJogador(db.Model):
    __tablename__ = 'avaliacoes_jogador'

    grupo_id = db.Column(db.Integer, db.ForeignKey('grupos.id', ondelete='CASCADE'), primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), primary_key=True)
    estrelas = db.Column(db.Integer, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), server_default=func.now())
    updated_at = db.Column(db.DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    grupo = db.relationship('Grupo', back_populates='avaliacoes')
    usuario = db.relationship('Usuario')

    __table_args__ = (
        CheckConstraint('estrelas >= 1 AND estrelas <= 5', name='ck_avaliacoes_estrelas'),
    )
