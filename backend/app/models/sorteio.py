from app.database import db
from sqlalchemy import func, CheckConstraint, UniqueConstraint


class Sorteio(db.Model):
    __tablename__ = 'sorteios'

    id = db.Column(db.Integer, primary_key=True)
    evento_id = db.Column(db.Integer, db.ForeignKey('eventos.id', ondelete='CASCADE'), unique=True, nullable=False, index=True)
    modalidade = db.Column(db.String(20), nullable=False)
    qtd_times = db.Column(db.Integer, nullable=False)
    max_jogadores_time = db.Column(db.Integer, nullable=True)
    qtd_goleiros_time = db.Column(db.Integer, nullable=True)
    status = db.Column(db.String(20), nullable=False, server_default='pendente')
    created_at = db.Column(db.DateTime(timezone=True), server_default=func.now())
    confirmado_em = db.Column(db.DateTime(timezone=True), nullable=True)

    evento = db.relationship('Evento', back_populates='sorteio')
    times = db.relationship('Time', back_populates='sorteio', cascade='all, delete-orphan', order_by='Time.ordem')

    __table_args__ = (
        CheckConstraint("modalidade IN ('aleatorio', 'balanceado')", name='ck_sorteios_modalidade'),
        CheckConstraint("status IN ('pendente', 'realizado', 'confirmado')", name='ck_sorteios_status'),
        CheckConstraint('qtd_times >= 2', name='ck_sorteios_qtd_times'),
    )


class Time(db.Model):
    __tablename__ = 'times'

    id = db.Column(db.Integer, primary_key=True)
    sorteio_id = db.Column(db.Integer, db.ForeignKey('sorteios.id', ondelete='CASCADE'), nullable=False, index=True)
    nome = db.Column(db.String(50), nullable=False)
    ordem = db.Column(db.Integer, nullable=False)

    sorteio = db.relationship('Sorteio', back_populates='times')
    jogadores = db.relationship('TimeJogador', back_populates='time', cascade='all, delete-orphan')

    __table_args__ = (
        UniqueConstraint('sorteio_id', 'ordem', name='uq_times_sorteio_ordem'),
        UniqueConstraint('sorteio_id', 'nome', name='uq_times_sorteio_nome'),
    )


class TimeJogador(db.Model):
    __tablename__ = 'time_jogadores'

    time_id = db.Column(db.Integer, db.ForeignKey('times.id', ondelete='CASCADE'), primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), primary_key=True)
    posicao = db.Column(db.String(20), nullable=False)
    estrelas = db.Column(db.Integer, nullable=False, server_default='3')
    eh_goleiro = db.Column(db.Boolean, default=False, server_default='false')

    time = db.relationship('Time', back_populates='jogadores')
    usuario = db.relationship('Usuario')
