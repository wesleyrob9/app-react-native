from app.database import db
from sqlalchemy import func, Index


class HistoricoAvaliacao(db.Model):
    __tablename__ = 'historico_avaliacoes'

    id = db.Column(db.Integer, primary_key=True)
    grupo_id = db.Column(db.Integer, db.ForeignKey('grupos.id', ondelete='CASCADE'), nullable=False)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), nullable=False)
    admin_id = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='SET NULL'), nullable=True)
    avaliacao_anterior = db.Column(db.Integer, nullable=True)
    avaliacao_nova = db.Column(db.Integer, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), server_default=func.now())

    grupo = db.relationship('Grupo', back_populates='historico_avaliacoes')
    usuario = db.relationship('Usuario', foreign_keys=[usuario_id])
    admin = db.relationship('Usuario', foreign_keys=[admin_id])

    __table_args__ = (
        Index('ix_historico_avaliacoes_grupo_usuario', 'grupo_id', 'usuario_id'),
    )
