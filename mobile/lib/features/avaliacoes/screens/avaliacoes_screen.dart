import 'package:flutter/material.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../models/avaliacao_model.dart';

class AvaliacoesScreen extends StatefulWidget {
  final int grupoId;
  const AvaliacoesScreen({super.key, required this.grupoId});

  @override
  State<AvaliacoesScreen> createState() => _AvaliacoesScreenState();
}

class _AvaliacoesScreenState extends State<AvaliacoesScreen> {
  late List<AvaliacaoModel> _avaliacoes;
  late bool _isAdmin;

  @override
  void initState() {
    super.initState();
    _avaliacoes = List.from(MockData.avaliacoesGrupo1);
    final grupo = MockData.grupos.firstWhere((g) => g.id == widget.grupoId);
    _isAdmin = grupo.isAdmin;
  }

  void _avaliar(AvaliacaoModel avaliacao, int novasEstrelas) {
    setState(() {
      final idx = _avaliacoes.indexOf(avaliacao);
      _avaliacoes[idx] = avaliacao.copyWith(estrelas: novasEstrelas);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${avaliacao.usuario.nomeExibicao}: $novasEstrelas ★ (mock)'),
          backgroundColor: AppColors.confirmed));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avaliações')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _avaliacoes.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final av = _avaliacoes[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(av.usuario.nome[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
            title: Text(av.usuario.nomeExibicao, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: PosicaoBadge(posicao: av.usuario.posicaoPrincipal),
            trailing: _isAdmin
                ? _StarEditor(stars: av.estrelas, onChanged: (v) => _avaliar(av, v))
                : StarRating(stars: av.estrelas),
          );
        },
      ),
    );
  }
}

class _StarEditor extends StatelessWidget {
  final int stars;
  final ValueChanged<int> onChanged;
  const _StarEditor({required this.stars, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) => GestureDetector(
      onTap: () => onChanged(i + 1),
      child: Icon(
        i < stars ? Icons.star : Icons.star_border,
        color: AppColors.starColor,
        size: 24,
      ),
    )),
  );
}
