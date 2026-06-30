import '../../auth/models/user_model.dart';

class SorteioModel {
  final int id;
  final int eventoId;
  final String modalidade;
  final int qtdTimes;
  final String status;
  final List<TimeModel> times;

  const SorteioModel({
    required this.id,
    required this.eventoId,
    required this.modalidade,
    required this.qtdTimes,
    required this.status,
    required this.times,
  });

  bool get isConfirmado => status == 'confirmado';
}

class TimeModel {
  final int id;
  final String nome;
  final int ordem;
  final List<JogadorSorteadoModel> jogadores;

  const TimeModel({
    required this.id,
    required this.nome,
    required this.ordem,
    required this.jogadores,
  });

  int get totalEstrelas => jogadores.fold(0, (sum, j) => sum + j.estrelas);
}

class JogadorSorteadoModel {
  final UserModel usuario;
  final String posicao;
  final int estrelas;
  final bool ehGoleiro;

  const JogadorSorteadoModel({
    required this.usuario,
    required this.posicao,
    required this.estrelas,
    required this.ehGoleiro,
  });
}
