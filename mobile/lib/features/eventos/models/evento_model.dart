import '../../auth/models/user_model.dart';

class EventoModel {
  final int id;
  final int grupoId;
  final String nome;
  final DateTime dataEvento;
  final String horario;
  final String local;
  final String? observacoes;
  final String statusConfirmacoes;
  final bool isActive;
  final int totalConfirmados;
  final int totalNaoVai;
  final int totalTalvez;
  final String? minhaResposta;
  final DateTime? canceladoEm;

  const EventoModel({
    required this.id,
    required this.grupoId,
    required this.nome,
    required this.dataEvento,
    required this.horario,
    required this.local,
    this.observacoes,
    required this.statusConfirmacoes,
    required this.isActive,
    required this.totalConfirmados,
    required this.totalNaoVai,
    required this.totalTalvez,
    this.minhaResposta,
    this.canceladoEm,
  });

  bool get isAberto => statusConfirmacoes == 'aberto' && isActive && canceladoEm == null;
  bool get isCancelado => canceladoEm != null;
  int get totalRespostas => totalConfirmados + totalNaoVai + totalTalvez;

  EventoModel copyWith({String? minhaResposta, String? statusConfirmacoes, int? totalConfirmados}) =>
      EventoModel(
        id: id, grupoId: grupoId, nome: nome, dataEvento: dataEvento,
        horario: horario, local: local, observacoes: observacoes,
        statusConfirmacoes: statusConfirmacoes ?? this.statusConfirmacoes,
        isActive: isActive,
        totalConfirmados: totalConfirmados ?? this.totalConfirmados,
        totalNaoVai: totalNaoVai, totalTalvez: totalTalvez,
        minhaResposta: minhaResposta ?? this.minhaResposta,
        canceladoEm: canceladoEm,
      );
}

class ParticipanteModel {
  final UserModel usuario;
  final String resposta;

  const ParticipanteModel({required this.usuario, required this.resposta});
}
