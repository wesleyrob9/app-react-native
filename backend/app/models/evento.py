from app.database import db
from sqlalchemy import func, CheckConstraint


class Evento(db.Model):
    __tablename__ = 'eventos'

    id = db.Column(db.Integer, primary_key=True)
    grupo_id = db.Column(db.Integer, db.ForeignKey('grupos.id', ondelete='CASCADE'), nullable=False, index=True)
    nome = db.Column(db.String(100), nullable=False)
    data_evento = db.Column(db.Date, nullable=False, index=True)
    horario = db.Column(db.Time, nullable=False)
    local = db.Column(db.String(255), nullable=False)
    observacoes = db.Column(db.Text, nullable=True)
    status_confirmacoes = db.Column(db.String(20), nullable=False, server_default='aberto')
    cancelado_em = db.Column(db.DateTime(timezone=True), nullable=True)
    motivo_cancelamento = db.Column(db.String(255), nullable=True)
    is_active = db.Column(db.Boolean, default=True, server_default='true')
    created_at = db.Column(db.DateTime(timezone=True), server_default=func.now())

    grupo = db.relationship('Grupo', back_populates='eventos')
    participantes = db.relationship('EventoParticipante', back_populates='evento', cascade='all, delete-orphan')
    sorteio = db.relationship('Sorteio', back_populates='evento', uselist=False, cascade='all, delete-orphan')

    __table_args__ = (
        CheckConstraint("status_confirmacoes IN ('aberto', 'encerrado')", name='ck_eventos_status'),
    )


class EventoParticipante(db.Model):
    __tablename__ = 'evento_participantes'

    evento_id = db.Column(db.Integer, db.ForeignKey('eventos.id', ondelete='CASCADE'), primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), primary_key=True, index=True)
    resposta = db.Column(db.String(20), nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), server_default=func.now())
    updated_at = db.Column(db.DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    evento = db.relationship('Evento', back_populates='participantes')
    usuario = db.relationship('Usuario', back_populates='evento_participacoes')

    __table_args__ = (
        CheckConstraint("resposta IN ('confirmado', 'nao_vou', 'talvez')", name='ck_evento_part_resposta'),
    )
