import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../logic/sorteio_logic.dart';
import '../models/sorteio_model.dart';

class ResultadoSorteioScreen extends StatelessWidget {
  final int grupoId;
  final int eventoId;
  const ResultadoSorteioScreen(
      {super.key, required this.grupoId, required this.eventoId});

  @override
  Widget build(BuildContext context) {
    final resultado = SorteioLogic.ultimoResultado;
    final sorteioMock = MockData.sorteioEvento3;

    final times = resultado?.times ?? sorteioMock.times;
    final modalidade = resultado?.modalidade ?? sorteioMock.modalidade;
    final qtdTimes = resultado?.qtdTimes ?? sorteioMock.qtdTimes;
    final excedentes = resultado?.excedentes ?? [];
    final goleirosExcedentes = resultado?.goleirosExcedentes ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado do Sorteio'),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Sorteio confirmado! (mock)'),
                  backgroundColor: AppColors.confirmed));
              context.pop();
            },
            child: const Text('Confirmar',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header com modalidade e total
          _HeaderInfo(modalidade: modalidade, qtdTimes: qtdTimes),
          const SizedBox(height: 12),

          // C: Banner de goleiros sem par
          if (goleirosExcedentes.isNotEmpty) ...[
            _BannerGoleirosExcedentes(goleiros: goleirosExcedentes),
            const SizedBox(height: 12),
          ],

          // Times
          ...times.map((t) => _TimeCard(time: t)),

          // B: Card de excedentes
          if (excedentes.isNotEmpty) ...[
            _CardExcedentes(excedentes: excedentes),
            const SizedBox(height: 16),
          ],

          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refazer sorteio'),
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── C: Banner goleiros excedentes ──
class _BannerGoleirosExcedentes extends StatelessWidget {
  final List<dynamic> goleiros;
  const _BannerGoleirosExcedentes({required this.goleiros});

  @override
  Widget build(BuildContext context) {
    final nomes = goleiros.map((g) => g.nomeExibicao as String).join(', ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🧤', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${goleiros.length} goleiro${goleiros.length > 1 ? 's' : ''} sem time fixo',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade900),
            ),
            const SizedBox(height: 2),
            Text(
              '$nomes — verifique em qual time cada um joga.',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Header ──
class _HeaderInfo extends StatelessWidget {
  final String modalidade;
  final int qtdTimes;
  const _HeaderInfo({required this.modalidade, required this.qtdTimes});

  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.primary,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _Info('Modalidade',
                modalidade == 'balanceado' ? 'Balanceado' : 'Aleatório'),
            _Info('Times', '$qtdTimes'),
            _Info('Status', 'Pendente'),
          ]),
        ),
      );
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  const _Info(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
      ]);
}

// ── Card de cada time ──
class _TimeCard extends StatelessWidget {
  final TimeModel time;
  const _TimeCard({required this.time});

  static const _colors = [
    AppColors.primary,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.red,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[(time.ordem - 1) % _colors.length];
    final jogadoresDeLinha = time.jogadores.where((j) => !j.ehGoleiro).toList();
    final goleiros = time.jogadores.where((j) => j.ehGoleiro).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              const Icon(Icons.shield, color: Colors.white),
              const SizedBox(width: 8),
              Text(time.nome,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Icon(Icons.star, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('${time.totalEstrelas}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
          // Jogadores de linha
          ...jogadoresDeLinha
              .map((j) => _JogadorTile(jogador: j, cor: color)),
          // Separador + goleiros
          if (goleiros.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(children: [
                const Text('🧤', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  'Goleiro${goleiros.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
              ]),
            ),
            ...goleiros.map((j) =>
                _JogadorTile(jogador: j, cor: Colors.orange.shade700)),
          ],
        ],
      ),
    );
  }
}

class _JogadorTile extends StatelessWidget {
  final JogadorSorteadoModel jogador;
  final Color cor;
  const _JogadorTile({required this.jogador, required this.cor});

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: cor.withOpacity(0.1),
          child: Text(jogador.usuario.nome[0],
              style: TextStyle(
                  color: cor, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        title: Text(jogador.usuario.nomeExibicao,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: PosicaoBadge(posicao: jogador.posicao),
        trailing: StarRating(stars: jogador.estrelas, size: 14),
      );
}

// ── B: Card de excedentes ──
class _CardExcedentes extends StatelessWidget {
  final List<dynamic> excedentes;
  const _CardExcedentes({required this.excedentes});

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.grey.shade50,
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(children: [
                Icon(Icons.person_off_outlined,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Ficaram de fora (${excedentes.length})',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'Excederam o número de vagas disponíveis. Foram sorteados aleatoriamente para ficar fora.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
            const Divider(height: 1),
            ...excedentes.map((u) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey.shade200,
                    child: Text(u.nome[0] as String,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600)),
                  ),
                  title: Text(u.nomeExibicao as String,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade700)),
                  subtitle: PosicaoBadge(posicao: u.posicaoPrincipal as String?),
                )),
            const SizedBox(height: 4),
          ],
        ),
      );
}
