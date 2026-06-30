import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/models/user_model.dart';
import '../../eventos/models/evento_model.dart';
import '../logic/sorteio_logic.dart';

class ConfigSorteioScreen extends StatefulWidget {
  final int grupoId;
  final int eventoId;
  const ConfigSorteioScreen({super.key, required this.grupoId, required this.eventoId});

  @override
  State<ConfigSorteioScreen> createState() => _ConfigSorteioScreenState();
}

class _ConfigSorteioScreenState extends State<ConfigSorteioScreen> {
  int _qtdTimes = 2;
  int _jogadoresDeLinha = 5;
  String _modalidade = 'balanceado';
  final List<TextEditingController> _nomesControllers = [
    TextEditingController(text: 'Time A'),
    TextEditingController(text: 'Time B'),
  ];
  bool _isLoading = false;
  String? _erroValidacao;

  // A: controle de inclusão por userId
  late Map<int, bool> _incluido;
  // A: posição substituída pontualmente
  late Map<int, String?> _posicaoOverride;
  // E: time fixado por userId → índice (0-based)
  late Map<int, int?> _timeForcado;
  // Convidados avulsos adicionados apenas para este sorteio (ids negativos)
  late List<ParticipanteModel> _convidados;
  int _proximoIdConvidado = -1;

  static const _posicoes = ['Goleiro', 'Zagueiro', 'Meio', 'Atacante'];

  List<ParticipanteModel> get _confirmadosDoGrupo =>
      MockData.participantesEvento1.where((p) => p.resposta == 'confirmado').toList();

  List<ParticipanteModel> get _todosConfirmados =>
      [..._confirmadosDoGrupo, ..._convidados];

  List<ParticipanteModel> get _incluidos =>
      _todosConfirmados.where((p) => _incluido[p.usuario.id] ?? true).toList();

  String _posicaoEfetiva(ParticipanteModel p) =>
      _posicaoOverride[p.usuario.id] ?? p.usuario.posicaoPrincipal ?? 'Meio';

  int get _totalAtivos => _incluidos.length;
  int get _totalGoleiros =>
      _incluidos.where((p) => _posicaoEfetiva(p) == 'Goleiro').length;
  int get _totalDeLinha => _totalAtivos - _totalGoleiros;
  int get _totalDeLinhaNecessario => _qtdTimes * _jogadoresDeLinha;

  @override
  void initState() {
    super.initState();
    _convidados = [];
    final todos = _todosConfirmados;
    _incluido = {for (final p in todos) p.usuario.id: true};
    _posicaoOverride = {};
    _timeForcado = {};
    _validar();
  }

  @override
  void dispose() {
    for (final c in _nomesControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _atualizarQtdTimes(int qtd) {
    setState(() {
      _qtdTimes = qtd;
      while (_nomesControllers.length < qtd) {
        _nomesControllers.add(TextEditingController(
            text: 'Time ${String.fromCharCode(65 + _nomesControllers.length)}'));
      }
      while (_nomesControllers.length > qtd) {
        _nomesControllers.removeLast().dispose();
      }
      // Remove fixações para times que não existem mais
      _timeForcado.removeWhere((_, v) => v != null && v >= qtd);
      _validar();
    });
  }

  void _validar() {
    if (_totalDeLinha < _totalDeLinhaNecessario) {
      _erroValidacao =
          'Jogadores de linha insuficientes: precisa de $_totalDeLinhaNecessario '
          '($_qtdTimes × $_jogadoresDeLinha), mas há apenas $_totalDeLinha '
          'de linha entre os $_totalAtivos incluídos.';
    } else {
      _erroValidacao = null;
    }
  }

  Future<void> _sortear() async {
    _validar();
    if (_erroValidacao != null) {
      setState(() {});
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final nomes = _nomesControllers.map((c) => c.text.trim()).toList();
    final fixados = <int, int>{};
    _timeForcado.forEach((uid, tIdx) {
      if (tIdx != null) fixados[uid] = tIdx;
    });

    SorteioLogic.executar(
      participantes: _todosConfirmados,
      qtdTimes: _qtdTimes,
      jogadoresDeLinha: _jogadoresDeLinha,
      modalidade: _modalidade,
      nomesDosTimes: nomes,
      incluidos: Map.from(_incluido),
      posicaoOverride: Map.from(_posicaoOverride),
      fixados: fixados,
    );

    context.pushReplacement(
        '/grupos/${widget.grupoId}/eventos/${widget.eventoId}/resultado');
  }

  void _mostrarEdicaoPosicao(ParticipanteModel p) {
    final atual = _posicaoEfetiva(p);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Posição de ${p.usuario.nomeExibicao}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Mudança válida apenas para este sorteio.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: _posicoes.map((pos) {
              final selecionado = pos == atual;
              return ChoiceChip(
                label: Text(pos),
                selected: selecionado,
                selectedColor: AppColors.primary,
                labelStyle:
                    TextStyle(color: selecionado ? Colors.white : AppColors.textPrimary),
                onSelected: (_) {
                  setState(() {
                    if (pos == p.usuario.posicaoPrincipal) {
                      _posicaoOverride.remove(p.usuario.id);
                    } else {
                      _posicaoOverride[p.usuario.id] = pos;
                    }
                    _validar();
                  });
                  Navigator.pop(context);
                },
              );
            }).toList()),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _mostrarEscolhaTime(ParticipanteModel p) {
    final nomes = _nomesControllers.map((c) => c.text.trim()).toList();
    final atual = _timeForcado[p.usuario.id];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fixar ${p.usuario.nomeExibicao} em um time',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('O jogador irá direto para o time escolhido.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shuffle, color: AppColors.primary),
              title: const Text('Sortear normalmente'),
              trailing: atual == null ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _timeForcado[p.usuario.id] = null);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ...List.generate(nomes.length, (i) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.shield_outlined,
                      color: _coresTimes[i % _coresTimes.length]),
                  title: Text(nomes[i]),
                  trailing: atual == i
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _timeForcado[p.usuario.id] = i);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static const _coresTimes = [
    AppColors.primary,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.red,
  ];

  void _adicionarConvidado() {
    final nomeCtrl = TextEditingController();
    String posicaoEscolhida = 'Meio';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Adicionar convidado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pessoa sem cadastro no grupo, válida apenas para este sorteio.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nomeCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome do convidado',
                  hintText: 'Ex: Convidado de Wesley',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Posição',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _posicoes.map((pos) {
                  final selecionado = pos == posicaoEscolhida;
                  return ChoiceChip(
                    label: Text(pos),
                    selected: selecionado,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                        color: selecionado ? Colors.white : AppColors.textPrimary),
                    onSelected: (_) =>
                        setDialogState(() => posicaoEscolhida = pos),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nome = nomeCtrl.text.trim();
                if (nome.isEmpty) return;
                final id = _proximoIdConvidado--;
                final convidado = UserModel(
                  id: id,
                  nome: nome,
                  email: 'convidado$id@local',
                  username: 'convidado$id',
                  posicaoPrincipal: posicaoEscolhida,
                );
                setState(() {
                  _convidados.add(
                      ParticipanteModel(usuario: convidado, resposta: 'confirmado'));
                  _incluido[id] = true;
                  _validar();
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _removerConvidado(int id) {
    setState(() {
      _convidados.removeWhere((p) => p.usuario.id == id);
      _incluido.remove(id);
      _posicaoOverride.remove(id);
      _timeForcado.remove(id);
      _validar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final todos = _todosConfirmados;
    final nomesTimes = _nomesControllers.map((c) => c.text.trim()).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar sorteio')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _ResumoJogadores(
            total: _totalAtivos,
            goleiros: _totalGoleiros,
            deLinha: _totalDeLinha,
          ),
          const SizedBox(height: 20),

          // ── Modalidade ──
          const Text('Modalidade',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Row(children: [
            _RadioCard(
              label: 'Balanceado',
              desc: 'Distribui por estrelas e posições',
              icon: Icons.balance,
              selected: _modalidade == 'balanceado',
              onTap: () => setState(() => _modalidade = 'balanceado'),
            ),
            const SizedBox(width: 12),
            _RadioCard(
              label: 'Aleatório',
              desc: 'Distribuição totalmente aleatória',
              icon: Icons.shuffle,
              selected: _modalidade == 'aleatorio',
              onTap: () => setState(() => _modalidade = 'aleatorio'),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Quantidade de times ──
          const Text('Quantidade de times',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          _Contador(
            valor: _qtdTimes,
            min: 2,
            max: 6,
            onChanged: _atualizarQtdTimes,
          ),
          const SizedBox(height: 24),

          // ── Jogadores de linha ──
          const Text('Jogadores de linha por time',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Goleiros são sorteados separadamente e adicionados ao fim de cada time.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _Contador(
            valor: _jogadoresDeLinha,
            min: 1,
            max: 10,
            onChanged: (v) => setState(() {
              _jogadoresDeLinha = v;
              _validar();
            }),
          ),
          const SizedBox(height: 8),
          _ResumoCalculo(
            qtdTimes: _qtdTimes,
            jogadoresDeLinha: _jogadoresDeLinha,
            totalDeLinha: _totalDeLinha,
            totalGoleiros: _totalGoleiros,
          ),
          const SizedBox(height: 24),

          // ── Nomes dos times ──
          const Text('Nomes dos times',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          ...List.generate(
              _qtdTimes,
              (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _nomesControllers[i],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Time ${i + 1}',
                        prefixIcon: const Icon(Icons.shield_outlined),
                      ),
                    ),
                  )),
          const SizedBox(height: 8),

          // ── A + E: Lista de participantes ──
          Row(children: [
            const Expanded(
              child: Text('Participantes confirmados',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            Text('${_totalAtivos}/${todos.length}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          const Text(
            'Desmarque quem não apareceu. Toque na posição para trocar. Toque em "→ Time" para fixar.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _adicionarConvidado,
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: const Text('Adicionar convidado'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: todos.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final uid = p.usuario.id;
                final ativo = _incluido[uid] ?? true;
                final posicao = _posicaoEfetiva(p);
                final timeFix = _timeForcado[uid];
                final temOverridePosicao = _posicaoOverride.containsKey(uid);
                final temFixTime = timeFix != null;
                final ehConvidado = uid < 0;

                return Column(
                  children: [
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: ativo
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey.shade200,
                        child: Text(
                          p.usuario.nome[0],
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color:
                                  ativo ? AppColors.primary : Colors.grey.shade400),
                        ),
                      ),
                      title: Row(children: [
                        Flexible(
                          child: Text(
                            p.usuario.nomeExibicao,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: ativo
                                  ? AppColors.textPrimary
                                  : Colors.grey.shade400,
                              decoration:
                                  ativo ? null : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        if (ehConvidado) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Convidado',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600)),
                          ),
                        ],
                      ]),
                      subtitle: ativo
                          ? Row(children: [
                              // Toque na posição para trocar
                              GestureDetector(
                                onTap: () => _mostrarEdicaoPosicao(p),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  PosicaoBadge(posicao: posicao),
                                  if (temOverridePosicao) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit,
                                        size: 11, color: AppColors.textSecondary),
                                  ],
                                ]),
                              ),
                              // E: indicador de time fixado
                              if (temFixTime) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _mostrarEscolhaTime(p),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _coresTimes[timeFix % _coresTimes.length]
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _coresTimes[
                                                timeFix % _coresTimes.length]
                                            .withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      '→ ${nomesTimes[timeFix]}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _coresTimes[
                                            timeFix % _coresTimes.length],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ])
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Remove convidado avulso (não existe no grupo)
                          if (ehConvidado)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.error),
                              tooltip: 'Remover convidado',
                              onPressed: () => _removerConvidado(uid),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (ehConvidado) const SizedBox(width: 8),
                          // E: botão fixar time (só quando ativo e sem fixação)
                          if (ativo && !temFixTime)
                            IconButton(
                              icon: const Icon(Icons.push_pin_outlined,
                                  size: 18, color: AppColors.textSecondary),
                              tooltip: 'Fixar em time',
                              onPressed: () => _mostrarEscolhaTime(p),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (ativo && !temFixTime) const SizedBox(width: 8),
                          // A: toggle incluir/excluir
                          Switch(
                            value: ativo,
                            onChanged: (v) => setState(() {
                              _incluido[uid] = v;
                              if (!v) {
                                _timeForcado[uid] = null;
                                _posicaoOverride.remove(uid);
                              }
                              _validar();
                            }),
                            activeColor: AppColors.primary,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Erro de validação
          if (_erroValidacao != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_erroValidacao!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: (_isLoading || _erroValidacao != null) ? null : _sortear,
            icon: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.casino),
            label: Text(_isLoading ? 'Sorteando...' : 'Realizar sorteio'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ──

class _ResumoJogadores extends StatelessWidget {
  final int total;
  final int goleiros;
  final int deLinha;
  const _ResumoJogadores(
      {required this.total, required this.goleiros, required this.deLinha});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _Chip(Icons.people, '$total', 'Incluídos', AppColors.primary),
            _Chip(Icons.sports_soccer, '$deLinha', 'De linha', Colors.blue.shade700),
            _Chip(Icons.sports_handball, '$goleiros',
                'Goleiro${goleiros != 1 ? 's' : ''}', Colors.orange.shade700),
          ]),
        ),
      );
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String valor;
  final String label;
  final Color cor;
  const _Chip(this.icon, this.valor, this.label, this.cor);

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: cor, size: 22),
        const SizedBox(height: 4),
        Text(valor,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cor)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]);
}

class _ResumoCalculo extends StatelessWidget {
  final int qtdTimes;
  final int jogadoresDeLinha;
  final int totalDeLinha;
  final int totalGoleiros;
  const _ResumoCalculo({
    required this.qtdTimes,
    required this.jogadoresDeLinha,
    required this.totalDeLinha,
    required this.totalGoleiros,
  });

  @override
  Widget build(BuildContext context) {
    final necessario = qtdTimes * jogadoresDeLinha;
    final ok = totalDeLinha >= necessario;
    final excedente = totalDeLinha - necessario;
    final goleirosPorTime = totalGoleiros ~/ qtdTimes;
    final goleirosRestantes = totalGoleiros % qtdTimes;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: ok ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
              ok ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 16,
              color: ok ? Colors.green.shade700 : AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$qtdTimes times × $jogadoresDeLinha de linha = $necessario jogadores necessários',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ok ? Colors.green.shade800 : AppColors.error),
            ),
          ),
        ]),
        if (ok) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              excedente > 0
                  ? '$excedente de linha ficará${excedente != 1 ? 'o' : ''} de fora'
                  : 'Encaixe perfeito — nenhum excedente de linha',
              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
            ),
          ),
          if (totalGoleiros > 0) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                goleirosRestantes == 0
                    ? '$goleirosPorTime goleiro${goleirosPorTime != 1 ? 's' : ''} por time'
                    : '$goleirosPorTime goleiro${goleirosPorTime != 1 ? 's' : ''} por time + $goleirosRestantes sem time fixo',
                style:
                    TextStyle(fontSize: 12, color: Colors.orange.shade700),
              ),
            ),
          ],
        ],
      ]),
    );
  }
}

class _Contador extends StatelessWidget {
  final int valor;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _Contador(
      {required this.valor,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          onPressed: valor > min ? () => onChanged(valor - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.primary,
          iconSize: 32,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$valor',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
        ),
        IconButton(
          onPressed: valor < max ? () => onChanged(valor + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.primary,
          iconSize: 32,
        ),
      ]);
}

class _RadioCard extends StatelessWidget {
  final String label;
  final String desc;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RadioCard(
      {required this.label,
      required this.desc,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.divider,
                  width: selected ? 2 : 1),
            ),
            child: Column(children: [
              Icon(icon,
                  color: selected ? Colors.white : AppColors.primary, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? Colors.white70
                          : AppColors.textSecondary)),
            ]),
          ),
        ),
      );
}
