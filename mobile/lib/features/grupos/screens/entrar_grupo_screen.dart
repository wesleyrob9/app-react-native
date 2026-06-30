import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class EntrarGrupoScreen extends StatefulWidget {
  const EntrarGrupoScreen({super.key});

  @override
  State<EntrarGrupoScreen> createState() => _EntrarGrupoScreenState();
}

class _EntrarGrupoScreenState extends State<EntrarGrupoScreen> {
  final _codigoCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() { _codigoCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_codigoCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isLoading = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Solicitação enviada!'),
          content: const Text('Sua solicitação foi enviada para os administradores do grupo. Aguarde a aprovação.'),
          actions: [
            ElevatedButton(
              onPressed: () { Navigator.pop(context); context.go('/grupos'); },
              child: const Text('Ok'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Entrar em grupo')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.vpn_key, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text('Código de convite', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Peça ao administrador do grupo o código de convite e insira abaixo.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _codigoCtrl,
            decoration: const InputDecoration(
              labelText: 'Código de convite',
              prefixIcon: Icon(Icons.tag),
              hintText: 'Ex: PQ2024AB',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Solicitar entrada'),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: const Text('💡 Mock: qualquer código funciona', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    ),
  );
}
