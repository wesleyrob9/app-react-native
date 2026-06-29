from app.database import db
from sqlalchemy import func


class PasswordResetToken(db.Model):
    __tablename__ = 'password_reset_tokens'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), nullable=False, index=True)
    token = db.Column(db.String(255), unique=True, nullable=False, index=True)
    expires_at = db.Column(db.DateTime(timezone=True), nullable=False)
    used = db.Column(db.Boolean, default=False, server_default='false')
    created_at = db.Column(db.DateTime(timezone=True), server_default=func.now())

    usuario = db.relationship('Usuario', back_populates='password_reset_tokens')
