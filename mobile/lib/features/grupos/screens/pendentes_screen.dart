import 'package:flutter/material.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class PendentesScreen extends StatefulWidget {
  final int grupoId;
  const PendentesScreen({super.key, required this.grupoId});

  @override
  State<PendentesScreen> createState() => _PendentesScreenState();
}

class _PendentesScreenState extends State<PendentesScreen> {
  late final pendentes = List.from(MockData.pendenteGrupo1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitações pendentes')),
      body: pendentes.isEmpty
          ? const EmptyWidget(message: 'Nenhuma solicitação pendente.', icon: Icons.how_to_reg)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pendentes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = pendentes[i];
                final u = m.usuario;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(u.nome[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(u.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                        PosicaoBadge(posicao: u.posicaoPrincipal),
                      ])),
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: AppColors.confirmed),
                        onPressed: () {
                          setState(() => pendentes.removeAt(i));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${u.nome} aprovado (mock)'), backgroundColor: AppColors.confirmed));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: AppColors.error),
                        onPressed: () {
                          setState(() => pendentes.removeAt(i));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${u.nome} rejeitado (mock)'), backgroundColor: AppColors.error));
                        },
                      ),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
