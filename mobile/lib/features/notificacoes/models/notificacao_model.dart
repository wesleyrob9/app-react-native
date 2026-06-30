class NotificacaoModel {
  final int id;
  final String tipo;
  final String titulo;
  final String? mensagem;
  bool lida;
  final DateTime criadoEm;

  NotificacaoModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.mensagem,
    required this.lida,
    required this.criadoEm,
  });
}
