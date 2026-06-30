import '../../auth/models/user_model.dart';

class GrupoModel {
  final int id;
  final String nome;
  final String? descricao;
  final String? logoUrl;
  final String? cidade;
  final String? codigoConvite;
  final int totalMembros;
  final String papel;

  const GrupoModel({
    required this.id,
    required this.nome,
    this.descricao,
    this.logoUrl,
    this.cidade,
    this.codigoConvite,
    required this.totalMembros,
    required this.papel,
  });

  bool get isAdmin => papel == 'admin';
}

class MembroModel {
  final UserModel usuario;
  final String papel;
  final int? estrelas;

  const MembroModel({
    required this.usuario,
    required this.papel,
    this.estrelas,
  });

  bool get isAdmin => papel == 'admin';
}
