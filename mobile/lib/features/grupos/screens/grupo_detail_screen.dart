import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../models/grupo_model.dart';

class GrupoDetailScreen extends StatelessWidget {
  final int grupoId;
  const GrupoDetailScreen({super.key, required this.grupoId});

  @override
  Widget build(BuildContext context) {
    final grupo = MockData.grupos.firstWhere((g) => g.id == grupoId,
        orElse: () => MockData.grupos.first);
    final eventos = grupoId == 1 ? MockData.eventosGrupo1 : MockData.eventosGrupo2;
    final proximosEventos = eventos.where((e) => !e.isCancelado && e.dataEvento.isAfter(DateTime.now())).take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(grupo.nome),
        actions: [
          if (grupo.isAdmin)
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Editar grupo (mock)')));
            }),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'sair') {
                _confirmarSaida(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'sair', child: Row(children: [
                Icon(Icons.exit_to_app, color: AppColors.error), SizedBox(width: 8),
                Text('Sair do grupo', style: TextStyle(color: AppColors.error)),
              ])),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          _HeaderCard(grupo: grupo),
          if (grupo.isAdmin) ...[
            const SectionHeader(title: 'Código de convite'),
            _CodigoConvite(codigo: grupo.codigoConvite ?? '--------'),
          ],
          const SectionHeader(title: 'Próximos eventos'),
          if (proximosEventos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Nenhum evento agendado.', style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            ...proximosEventos.map((e) => ListTile(
              leading: const Icon(Icons.event, color: AppColors.primary),
              title: Text(e.nome),
              subtitle: Text('${e.dataEvento.day}/${e.dataEvento.month} às ${e.horario}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/grupos/$grupoId/eventos/${e.id}'),
            )),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.event_outlined, color: AppColors.primary),
            title: const Text('Ver todos os eventos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/grupos/$grupoId/eventos'),
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined, color: AppColors.primary),
            title: const Text('Membros'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('${grupo.totalMembros}', style: const TextStyle(color: AppColors.textSecondary)),
              const Icon(Icons.chevron_right),
            ]),
            onTap: () => context.push('/grupos/$grupoId/membros'),
          ),
          ListTile(
            leading: const Icon(Icons.star_outlined, color: AppColors.starColor),
            title: const Text('Avaliações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/grupos/$grupoId/avaliacoes'),
          ),
          if (grupo.isAdmin) ...[
            const Divider(height: 1),
            const SectionHeader(title: 'Administração'),
            ListTile(
              leading: const Icon(Icons.pending_actions, color: AppColors.primary),
              title: const Text('Solicitações pendentes'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (MockData.pendenteGrupo1.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                    child: Text('${MockData.pendenteGrupo1.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                const Icon(Icons.chevron_right),
              ]),
              onTap: () => context.push('/grupos/$grupoId/pendentes'),
            ),
            if (grupo.isAdmin)
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                title: const Text('Criar evento'),
                onTap: () => context.push('/grupos/$grupoId/eventos/criar'),
              ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _confirmarSaida(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair do grupo'),
        content: const Text('Tem certeza que deseja sair deste grupo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () { Navigator.pop(context); context.pop(); },
            child: const Text('Sair', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final GrupoModel grupo;
  const _HeaderCard({required this.grupo});

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.primary,
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
          child: Center(child: Text(grupo.nome[0], style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(height: 12),
        Text(grupo.nome, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        if (grupo.cidade != null)
          Text(grupo.cidade!, style: const TextStyle(color: Colors.white70)),
        if (grupo.descricao != null) ...[
          const SizedBox(height: 8),
          Text(grupo.descricao!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.group, color: Colors.white70, size: 16),
          const SizedBox(width: 4),
          Text('${grupo.totalMembros} membros', style: const TextStyle(color: Colors.white70)),
        ]),
      ],
    ),
  );
}

class _CodigoConvite extends StatelessWidget {
  final String codigo;
  const _CodigoConvite({required this.codigo});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        const Icon(Icons.vpn_key, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(codigo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.copy, color: AppColors.primary),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: codigo));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Código copiado!')));
          },
        ),
      ]),
    ),
  );
}
