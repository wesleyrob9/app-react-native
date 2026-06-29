from app.database import db
from sqlalchemy import func, CheckConstraint, Index

TIPOS_NOTIFICACAO = (
    'novo_evento', 'aprovacao_grupo', 'sorteio_iniciado',
    'sorteio_finalizado', 'rejeicao_grupo', 'promovido_admin', 'removido_grupo'
)


class Notificacao(db.Model):
    __tablename__ = 'notificacoes'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), nullable=False)
    tipo = db.Column(db.String(30), nullable=False)
    titulo = db.Column(db.String(150), nullable=False)
    mensagem = db.Column(db.Text, nullable=True)
    referencia_tipo = db.Column(db.String(30), nullable=True)
    referencia_id = db.Column(db.Integer, nullable=True)
    lida = db.Column(db.Boolean, default=False, server_default='false')
    created_at = db.Column(db.DateTime(timezone=True), server_default=func.now())

    usuario = db.relationship('Usuario', back_populates='notificacoes')

    __table_args__ = (
        CheckConstraint(
            f"tipo IN {TIPOS_NOTIFICACAO}",
            name='ck_notificacoes_tipo'
        ),
        Index('ix_notificacoes_usuario_lida', 'usuario_id', 'lida'),
        Index('ix_notificacoes_created_at', 'created_at'),
    )
