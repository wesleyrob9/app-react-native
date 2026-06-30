import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notificacao_model.dart';
import '../../../core/mock/mock_data.dart';

class NotificacoesNotifier extends StateNotifier<List<NotificacaoModel>> {
  NotificacoesNotifier() : super(List.from(MockData.notificacoes));

  int get naoLidas => state.where((n) => !n.lida).length;

  void marcarLida(int id) {
    state = state.map((n) => n.id == id ? (n..lida = true) : n).toList();
    state = List.from(state);
  }

  void marcarTodasLidas() {
    for (final n in state) { n.lida = true; }
    state = List.from(state);
  }
}

final notificacoesProvider = StateNotifierProvider<NotificacoesNotifier, List<NotificacaoModel>>(
  (_) => NotificacoesNotifier(),
);

final badgeProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificacoesProvider);
  return notifs.where((n) => !n.lida).length;
});
