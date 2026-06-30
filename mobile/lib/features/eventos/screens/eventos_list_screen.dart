import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../models/evento_model.dart';
import 'package:intl/intl.dart';

class EventosListScreen extends StatelessWidget {
  final int grupoId;
  const EventosListScreen({super.key, required this.grupoId});

  @override
  Widget build(BuildContext context) {
    final grupo = MockData.grupos.firstWhere((g) => g.id == grupoId, orElse: () => MockData.grupos.first);
    final eventos = grupoId == 1 ? MockData.eventosGrupo1 : MockData.eventosGrupo2;

    return Scaffold(
      appBar: AppBar(title: Text('Eventos - ${grupo.nome}')),
      body: eventos.isEmpty
          ? const EmptyWidget(message: 'Nenhum evento criado ainda.', icon: Icons.event_outlined)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: eventos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _EventoCard(evento: eventos[i], grupoId: grupoId),
            ),
      floatingActionButton: grupo.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/grupos/$grupoId/eventos/criar'),
              icon: const Icon(Icons.add),
              label: const Text('Novo evento'),
            )
          : null,
    );
  }
}

class _EventoCard extends StatelessWidget {
  final EventoModel evento;
  final int grupoId;
  const _EventoCard({required this.evento, required this.grupoId});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM');
    final isPast = evento.dataEvento.isBefore(DateTime.now());

    return Card(
      child: InkWell(
        onTap: () => context.push('/grupos/$grupoId/eventos/${evento.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isPast ? Colors.grey.shade100 : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(evento.dataEvento.day.toString().padLeft(2, '0'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                        color: isPast ? Colors.grey : AppColors.primary)),
                Text(fmt.format(evento.dataEvento).split('/')[1] == '07' ? 'JUL' :
                     fmt.format(evento.dataEvento).split('/')[1] == '06' ? 'JUN' : 'AGO',
                    style: TextStyle(fontSize: 10, color: isPast ? Colors.grey : AppColors.primary)),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(evento.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Text(evento.horario, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Expanded(child: Text(evento.local, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                _StatusChip(statusConfirmacoes: evento.statusConfirmacoes, isCancelado: evento.isCancelado),
                const SizedBox(width: 8),
                Icon(Icons.check_circle, size: 14, color: AppColors.confirmed),
                const SizedBox(width: 2),
                Text('${evento.totalConfirmados}', style: const TextStyle(fontSize: 12)),
                if (evento.minhaResposta != null) ...[
                  const SizedBox(width: 8),
                  _MinhaRespostaChip(resposta: evento.minhaResposta!),
                ],
              ]),
            ])),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ]),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String statusConfirmacoes;
  final bool isCancelado;
  const _StatusChip({required this.statusConfirmacoes, required this.isCancelado});

  @override
  Widget build(BuildContext context) {
    if (isCancelado) return _chip('Cancelado', AppColors.error);
    if (statusConfirmacoes == 'encerrado') return _chip('Encerrado', Colors.orange);
    return _chip('Aberto', AppColors.confirmed);
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );
}

class _MinhaRespostaChip extends StatelessWidget {
  final String resposta;
  const _MinhaRespostaChip({required this.resposta});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (resposta) {
      case 'confirmado': color = AppColors.confirmed; label = 'Confirmei'; break;
      case 'nao_vou': color = AppColors.error; label = 'Não vou'; break;
      default: color = AppColors.maybe; label = 'Talvez';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
