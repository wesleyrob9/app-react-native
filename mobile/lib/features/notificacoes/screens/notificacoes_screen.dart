import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../models/notificacao_model.dart';
import '../providers/notificacoes_provider.dart';
import 'package:intl/intl.dart';

class NotificacoesScreen extends ConsumerWidget {
  const NotificacoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificacoesProvider);
    final notifier = ref.read(notificacoesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          if (notifs.any((n) => !n.lida))
            TextButton(
              onPressed: () => notifier.marcarTodasLidas(),
              child: const Text('Marcar todas', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: notifs.isEmpty
          ? const EmptyWidget(message: 'Nenhuma notificação.', icon: Icons.notifications_off_outlined)
          : ListView.separated(
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _NotifTile(notif: notifs[i], onTap: () => notifier.marcarLida(notifs[i].id)),
            ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificacaoModel notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  IconData get _icon {
    switch (notif.tipo) {
      case 'novo_evento': return Icons.event;
      case 'aprovacao_grupo': return Icons.check_circle;
      case 'rejeicao_grupo': return Icons.cancel;
      case 'sorteio_finalizado': return Icons.emoji_events;
      case 'promovido_admin': return Icons.star;
      default: return Icons.notifications;
    }
  }

  Color get _color {
    switch (notif.tipo) {
      case 'novo_evento': return AppColors.primary;
      case 'aprovacao_grupo': return AppColors.confirmed;
      case 'rejeicao_grupo': return AppColors.error;
      case 'sorteio_finalizado': return AppColors.starColor;
      case 'promovido_admin': return AppColors.adminBadge;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(notif.criadoEm);
    return ListTile(
      onTap: onTap,
      tileColor: notif.lida ? null : AppColors.primary.withOpacity(0.04),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: _color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(_icon, color: _color),
      ),
      title: Text(notif.titulo, style: TextStyle(
        fontWeight: notif.lida ? FontWeight.normal : FontWeight.w700,
        fontSize: 14,
      )),
      subtitle: notif.mensagem != null ? Text(notif.mensagem!, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13)) : null,
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        if (!notif.lida)
          const SizedBox(height: 4),
        if (!notif.lida)
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
      ]),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd/MM').format(dt);
  }
}
