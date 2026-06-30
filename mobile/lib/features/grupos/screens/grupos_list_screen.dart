import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../notificacoes/providers/notificacoes_provider.dart';
import '../models/grupo_model.dart';

class GruposListScreen extends ConsumerWidget {
  const GruposListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grupos = MockData.grupos;
    final badge = ref.watch(badgeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Grupos'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notificacoes'),
              ),
              if (badge > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/perfil'),
          ),
        ],
      ),
      body: grupos.isEmpty
          ? const EmptyWidget(message: 'Você não participa de nenhum grupo ainda.', icon: Icons.group_outlined)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: grupos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _GrupoCard(grupo: grupos[i]),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'entrar',
            onPressed: () => context.push('/grupos/entrar'),
            icon: const Icon(Icons.login),
            label: const Text('Entrar'),
            backgroundColor: AppColors.primaryLight,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'criar',
            onPressed: () => context.push('/grupos/criar'),
            icon: const Icon(Icons.add),
            label: const Text('Criar grupo'),
          ),
        ],
      ),
    );
  }
}

class _GrupoCard extends StatelessWidget {
  final GrupoModel grupo;
  const _GrupoCard({required this.grupo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/grupos/${grupo.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _GrupoAvatar(nome: grupo.nome),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(grupo.nome, style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                        ),
                        if (grupo.isAdmin)
                          const RoleBadge(papel: 'admin'),
                      ],
                    ),
                    if (grupo.cidade != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(grupo.cidade!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ]),
                    ],
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.group_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('${grupo.totalMembros} membros', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ]),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrupoAvatar extends StatelessWidget {
  final String nome;
  const _GrupoAvatar({required this.nome});

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(
      child: Text(
        nome.isNotEmpty ? nome[0].toUpperCase() : 'G',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    ),
  );
}
