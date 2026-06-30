import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

const _posicoes = ['Goleiro', 'Zagueiro', 'Meio', 'Atacante'];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _apelidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmSenhaCtrl = TextEditingController();
  String? _posicaoPrincipal;
  String? _posicaoSecundaria;
  bool _senhaVisivel = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeCtrl.dispose(); _apelidoCtrl.dispose(); _emailCtrl.dispose();
    _usernameCtrl.dispose(); _senhaCtrl.dispose(); _confirmSenhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).register(
      nome: _nomeCtrl.text.trim(),
      apelido: _apelidoCtrl.text.trim(),
      email: _emailCtrl.text.trim().toLowerCase(),
      username: _usernameCtrl.text.trim().toLowerCase(),
      senha: _senhaCtrl.text,
      posicaoPrincipal: _posicaoPrincipal,
      posicaoSecundaria: _posicaoSecundaria,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _field(_nomeCtrl, 'Nome completo', Icons.person_outline,
              validator: (v) => (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null),
            const SizedBox(height: 16),
            _field(_apelidoCtrl, 'Apelido (opcional)', Icons.sports_soccer),
            const SizedBox(height: 16),
            _field(_emailCtrl, 'E-mail', Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null),
            const SizedBox(height: 16),
            _field(_usernameCtrl, 'Nome de usuário', Icons.alternate_email,
              validator: (v) => (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null),
            const SizedBox(height: 16),
            TextFormField(
              controller: _senhaCtrl,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_senhaVisivel ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                ),
              ),
              obscureText: !_senhaVisivel,
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmSenhaCtrl,
              decoration: const InputDecoration(
                labelText: 'Confirmar senha',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (v) => v != _senhaCtrl.text ? 'Senhas não conferem' : null,
            ),
            const SizedBox(height: 24),
            const Text('Posição (opcional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _posicoes.map((p) => ChoiceChip(
                label: Text(p, style: TextStyle(fontSize: 13,
                  color: _posicaoPrincipal == p ? Colors.white : AppColors.textPrimary)),
                selected: _posicaoPrincipal == p,
                selectedColor: AppColors.primary,
                onSelected: (_) => setState(() => _posicaoPrincipal = _posicaoPrincipal == p ? null : p),
              )).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Criar conta'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Já tem conta? ', style: TextStyle(color: AppColors.textSecondary)),
                TextButton(onPressed: () => context.pop(), child: const Text('Entrar')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) =>
    TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      validator: validator,
    );
}
