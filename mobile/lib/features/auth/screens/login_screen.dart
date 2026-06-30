import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _senhaVisivel = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final creds = await AuthStorage.getSavedCredentials();
    if (creds != null && mounted) {
      setState(() {
        _loginCtrl.text = creds['login'] ?? '';
        _senhaCtrl.text = creds['senha'] ?? '';
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _loginCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(authProvider.notifier).login(
      _loginCtrl.text.trim(),
      _senhaCtrl.text,
      rememberMe: _rememberMe,
    );
    if (mounted) setState(() => _isLoading = false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authProvider).error ?? 'Erro ao fazer login'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.sports_soccer, size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text('Fut Grupos', style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700,
                    )),
                    Text('Organize sua pelada', style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 14,
                    )),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const SizedBox(height: 8),
                      Text('Entrar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                      )),
                      const SizedBox(height: 4),
                      const Text('Use seu usuario ou e-mail', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _loginCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Usuário ou E-mail',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu usuário ou e-mail' : null,
                      ),
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
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => (v == null || v.isEmpty) ? 'Informe sua senha' : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                            activeColor: AppColors.primary,
                          ),
                          const Text('Lembrar login', style: TextStyle(color: AppColors.textSecondary)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.push('/esqueci-senha'),
                            child: const Text('Esqueci a senha'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Entrar'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => context.push('/registro'),
                        child: const Text('Criar conta'),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Text(
                            '👆 Mock: login xavs10 / senha 123456',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
