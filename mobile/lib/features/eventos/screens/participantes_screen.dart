import 'package:flutter/material.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../models/evento_model.dart';

class ParticipantesScreen extends StatelessWidget {
  final int grupoId;
  final int eventoId;
  const ParticipantesScreen({super.key, required this.grupoId, required this.eventoId});

  @override
  Widget build(BuildContext context) {
    final participantes = MockData.participantesEvento1;
    final confirmados = participantes.where((p) => p.resposta == 'confirmado').toList();
    final talvez = participantes.where((p) => p.resposta == 'talvez').toList();
    final naoVao = participantes.where((p) => p.resposta == 'nao_vou').toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Participantes'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Confirmados (${confirmados.length})'),
              Tab(text: 'Talvez (${talvez.length})'),
              Tab(text: 'Não vão (${naoVao.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Lista(participantes: confirmados, cor: AppColors.confirmed),
            _Lista(participantes: talvez, cor: AppColors.maybe),
            _Lista(participantes: naoVao, cor: AppColors.error),
          ],
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  final List<ParticipanteModel> participantes;
  final Color cor;
  const _Lista({required this.participantes, required this.cor});

  @override
  Widget build(BuildContext context) {
    if (participantes.isEmpty) {
      return const EmptyWidget(message: 'Nenhum participante nessa categoria.', icon: Icons.people_outline);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: participantes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final u = participantes[i].usuario;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: cor.withOpacity(0.1),
            child: Text(u.nome[0], style: TextStyle(color: cor, fontWeight: FontWeight.w700)),
          ),
          title: Text(u.nomeExibicao, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: PosicaoBadge(posicao: u.posicaoPrincipal),
        );
      },
    );
  }
}
