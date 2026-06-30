import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class CriarEventoScreen extends StatefulWidget {
  final int grupoId;
  const CriarEventoScreen({super.key, required this.grupoId});

  @override
  State<CriarEventoScreen> createState() => _CriarEventoScreenState();
}

class _CriarEventoScreenState extends State<CriarEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  DateTime? _data;
  TimeOfDay? _horario;
  bool _isLoading = false;

  @override
  void dispose() { _nomeCtrl.dispose(); _localCtrl.dispose(); _obsCtrl.dispose(); super.dispose(); }

  Future<void> _pickData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _data = picked);
  }

  Future<void> _pickHorario() async {
    final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
    if (picked != null) setState(() => _horario = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_data == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione a data'))); return; }
    if (_horario == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione o horário'))); return; }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Evento "${_nomeCtrl.text}" criado! (mock)'), backgroundColor: AppColors.confirmed));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Criar evento')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _nomeCtrl,
            decoration: const InputDecoration(labelText: 'Nome do evento *', prefixIcon: Icon(Icons.event)),
            validator: (v) => (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickData,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Data *',
                      prefixIcon: const Icon(Icons.calendar_today),
                      hintText: _data == null ? 'Selecionar' : DateFormat('dd/MM/yyyy').format(_data!),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _pickHorario,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Horário *',
                      prefixIcon: const Icon(Icons.access_time),
                      hintText: _horario == null ? 'Selecionar' : _horario!.format(context),
                    ),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextFormField(
            controller: _localCtrl,
            decoration: const InputDecoration(labelText: 'Local *', prefixIcon: Icon(Icons.location_on_outlined)),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o local' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _obsCtrl,
            decoration: const InputDecoration(labelText: 'Observações (opcional)', prefixIcon: Icon(Icons.notes)),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Criar evento'),
          ),
        ],
      ),
    ),
  );
}
