import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../models/evento_model.dart';

class EventoDetailScreen extends StatefulWidget {
  final int grupoId;
  final int eventoId;
  const EventoDetailScreen({super.key, required this.grupoId, required this.eventoId});

  @override
  State<EventoDetailScreen> createState() => _EventoDetailScreenState();
}

class _EventoDetailScreenState extends State<EventoDetailScreen> {
  late EventoModel _evento;
  late bool _isAdmin;

  @override
  void initState() {
    super.initState();
    final todos = [...MockData.eventosGrupo1, ...MockData.eventosGrupo2];
    _evento = todos.firstWhere((e) => e.id == widget.eventoId);
    final grupo = MockData.grupos.firstWhere((g) => g.id == widget.grupoId);
    _isAdmin = grupo.isAdmin;
  }

  void _responder(String resposta) {
    setState(() => _evento = _evento.copyWith(minhaResposta: resposta));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Presença atualizada: $resposta (mock)'), backgroundColor: AppColors.confirmed));
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(_evento.dataEvento);

    return Scaffold(
      appBar: AppBar(
        title: Text(_evento.nome),
        actions: [
          if (_isAdmin)
            PopupMenuButton<String>(
              onSelected: (v) => _handleAdmin(v),
              itemBuilder: (_) => [
                if (_evento.isAberto)
                  const PopupMenuItem(value: 'encerrar', child: Text('Encerrar confirmações')),
                if (!_evento.isAberto && !_evento.isCancelado)
                  const PopupMenuItem(value: 'reabrir', child: Text('Reabrir confirmações')),
                const PopupMenuItem(value: 'cancelar', child: Text('Cancelar evento',
                    style: TextStyle(color: AppColors.error))),
              ],
            ),
        ],
      ),
      body: ListView(
        children: [
          _InfoCard(evento: _evento, dateStr: dateStr),
          if (!_evento.isCancelado && _evento.isAberto)
            _PresencaCard(minha: _evento.minhaResposta, onResponder: _responder),
          _ContadoresCard(evento: _evento),
          ListTile(
            leading: const Icon(Icons.people_outline, color: AppColors.primary),
            title: const Text('Ver participantes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/grupos/${widget.grupoId}/eventos/${widget.eventoId}/participantes'),
          ),
          if (_isAdmin && _evento.statusConfirmacoes == 'encerrado' && !_evento.isCancelado)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.casino),
                label: const Text('Fazer sorteio'),
                onPressed: () => context.push('/grupos/${widget.grupoId}/eventos/${widget.eventoId}/sorteio'),
              ),
            ),
          if (_evento.statusConfirmacoes == 'encerrado' && !_evento.isCancelado)
            ListTile(
              leading: const Icon(Icons.emoji_events, color: AppColors.starColor),
              title: const Text('Ver resultado do sorteio'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/grupos/${widget.grupoId}/eventos/${widget.eventoId}/resultado'),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _handleAdmin(String action) {
    switch (action) {
      case 'encerrar':
        setState(() => _evento = _evento.copyWith(statusConfirmacoes: 'encerrado'));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirmações encerradas (mock)'), backgroundColor: AppColors.confirmed));
        break;
      case 'reabrir':
        setState(() => _evento = _evento.copyWith(statusConfirmacoes: 'aberto'));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirmações reabertas (mock)')));
        break;
      case 'cancelar':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento cancelado (mock)'), backgroundColor: AppColors.error));
        context.pop();
        break;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final EventoModel evento;
  final String dateStr;
  const _InfoCard({required this.evento, required this.dateStr});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.access_time, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(evento.horario),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(evento.local)),
        ]),
        if (evento.observacoes != null) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(evento.observacoes!, style: const TextStyle(color: AppColors.textSecondary))),
          ]),
        ],
      ]),
    ),
  );
}

class _PresencaCard extends StatelessWidget {
  final String? minha;
  final void Function(String) onResponder;
  const _PresencaCard({required this.minha, required this.onResponder});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Sua presença', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        Row(children: [
          _BotaoPresenca(label: 'Vou!', icon: Icons.check_circle, color: AppColors.confirmed,
            selected: minha == 'confirmado', onTap: () => onResponder('confirmado')),
          const SizedBox(width: 8),
          _BotaoPresenca(label: 'Não vou', icon: Icons.cancel, color: AppColors.error,
            selected: minha == 'nao_vou', onTap: () => onResponder('nao_vou')),
          const SizedBox(width: 8),
          _BotaoPresenca(label: 'Talvez', icon: Icons.help_outline, color: AppColors.maybe,
            selected: minha == 'talvez', onTap: () => onResponder('talvez')),
        ]),
      ]),
    ),
  );
}

class _BotaoPresenca extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _BotaoPresenca({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? Colors.white : color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: selected ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );
}

class _ContadoresCard extends StatelessWidget {
  final EventoModel evento;
  const _ContadoresCard({required this.evento});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        _Contador('Confirmados', evento.totalConfirmados, AppColors.confirmed),
        _Contador('Talvez', evento.totalTalvez, AppColors.maybe),
        _Contador('Não vão', evento.totalNaoVai, AppColors.error),
      ]),
    ),
  );
}

class _Contador extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _Contador(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );
}
