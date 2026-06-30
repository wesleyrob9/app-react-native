import 'package:flutter/material.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../models/grupo_model.dart';

class MembrosScreen extends StatelessWidget {
  final int grupoId;
  const MembrosScreen({super.key, required this.grupoId});

  @override
  Widget build(BuildContext context) {
    final grupo = MockData.grupos.firstWhere((g) => g.id == grupoId, orElse: () => MockData.grupos.first);
    final membros = grupoId == 1 ? MockData.membrosGrupo1 : MockData.membrosGrupo2;
    final admins = membros.where((m) => m.isAdmin).toList();
    final outros = membros.where((m) => !m.isAdmin).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Membros - ${grupo.nome}')),
      body: ListView(
        children: [
          const SectionHeader(title: 'Administradores'),
          ...admins.map((m) => _MembroTile(membro: m, grupoIsAdmin: grupo.isAdmin)),
          const SectionHeader(title: 'Membros'),
          ...outros.map((m) => _MembroTile(membro: m, grupoIsAdmin: grupo.isAdmin)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MembroTile extends StatelessWidget {
  final MembroModel membro;
  final bool grupoIsAdmin;
  const _MembroTile({required this.membro, required this.grupoIsAdmin});

  @override
  Widget build(BuildContext context) {
    final u = membro.usuario;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Text(u.nome[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
      ),
      title: Row(children: [
        Text(u.nomeExibicao, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        RoleBadge(papel: membro.papel),
      ]),
      subtitle: Row(children: [
        PosicaoBadge(posicao: u.posicaoPrincipal),
        if (membro.estrelas != null) ...[
          const SizedBox(width: 8),
          StarRating(stars: membro.estrelas!),
        ],
      ]),
      trailing: grupoIsAdmin ? PopupMenuButton<String>(
        onSelected: (v) => _handleAction(context, v, u.nome),
        itemBuilder: (_) => [
          if (!membro.isAdmin)
            const PopupMenuItem(value: 'promover', child: Text('Promover a admin')),
          if (membro.isAdmin)
            const PopupMenuItem(value: 'rebaixar', child: Text('Remover admin')),
          PopupMenuItem(
            value: 'remover',
            child: Text('Remover do grupo', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ) : null,
    );
  }

  void _handleAction(BuildContext context, String action, String nome) {
    String msg = '';
    switch (action) {
      case 'promover': msg = '$nome promovido a administrador (mock)'; break;
      case 'rebaixar': msg = '$nome removido de administrador (mock)'; break;
      case 'remover': msg = '$nome removido do grupo (mock)'; break;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
