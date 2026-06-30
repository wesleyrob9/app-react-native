import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class CriarGrupoScreen extends StatefulWidget {
  const CriarGrupoScreen({super.key});

  @override
  State<CriarGrupoScreen> createState() => _CriarGrupoScreenState();
}

class _CriarGrupoScreenState extends State<CriarGrupoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() { _nomeCtrl.dispose(); _descCtrl.dispose(); _cidadeCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Grupo "${_nomeCtrl.text}" criado! (mock)'), backgroundColor: AppColors.confirmed));
      context.go('/grupos');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Criar grupo')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.group_add, size: 40, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nomeCtrl,
            decoration: const InputDecoration(labelText: 'Nome do grupo *', prefixIcon: Icon(Icons.group)),
            validator: (v) => (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Descrição (opcional)', prefixIcon: Icon(Icons.description_outlined)),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cidadeCtrl,
            decoration: const InputDecoration(labelText: 'Cidade (opcional)', prefixIcon: Icon(Icons.location_on_outlined)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Criar grupo'),
          ),
        ],
      ),
    ),
  );
}
