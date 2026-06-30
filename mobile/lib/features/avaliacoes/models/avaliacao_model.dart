import '../../auth/models/user_model.dart';

class AvaliacaoModel {
  final UserModel usuario;
  final int estrelas;
  final int grupoId;

  const AvaliacaoModel({
    required this.usuario,
    required this.estrelas,
    required this.grupoId,
  });

  AvaliacaoModel copyWith({int? estrelas}) => AvaliacaoModel(
    usuario: usuario, estrelas: estrelas ?? this.estrelas, grupoId: grupoId);
}

class HistoricoAvaliacaoModel {
  final String adminNome;
  final int avaliacaoAnterior;
  final int avaliacaoNova;
  final DateTime updatedAt;

  const HistoricoAvaliacaoModel({
    required this.adminNome,
    required this.avaliacaoAnterior,
    required this.avaliacaoNova,
    required this.updatedAt,
  });
}
