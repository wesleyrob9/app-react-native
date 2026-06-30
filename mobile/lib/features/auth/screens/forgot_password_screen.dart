import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;
  bool _isLoading = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() { _isLoading = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Esqueci a senha')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent ? _successView() : _formView(),
      ),
    );
  }

  Widget _formView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
      const SizedBox(height: 16),
      Text('Recuperar senha', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Informe seu e-mail e enviaremos as instruções de recuperação.',
          style: TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      TextFormField(
        controller: _emailCtrl,
        decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)),
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Enviar instruções'),
      ),
    ],
  );

  Widget _successView() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.mark_email_read_outlined, size: 80, color: AppColors.confirmed),
      const SizedBox(height: 24),
      Text('E-mail enviado!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      const Text('Se o e-mail estiver cadastrado, você receberá as instruções em breve.',
          textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: () => context.pop(),
        child: const Text('Voltar ao login'),
      ),
    ],
  );
}
