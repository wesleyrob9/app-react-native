import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_config.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

const _posicoes = ['Goleiro', 'Zagueiro', 'Meio', 'Atacante'];

// Avatares emoji disponíveis para escolha
const _avatares = ['⚽', '🧤', '🥅', '🏆', '⭐', '🦁', '🐯', '🦅', '🔥', '💪', '🎯', '🏅'];

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _editMode = false;
  late TextEditingController _nomeCtrl;
  late TextEditingController _apelidoCtrl;
  late TextEditingController _fotoUrlCtrl;
  String? _posicaoPrincipal;
  String? _avatarSelecionado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user!;
    _nomeCtrl = TextEditingController(text: user.nome);
    _apelidoCtrl = TextEditingController(text: user.apelido ?? '');
    _fotoUrlCtrl = TextEditingController(text: user.fotoUrl ?? '');
    _posicaoPrincipal = user.posicaoPrincipal;
    _avatarSelecionado = user.avatar;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _apelidoCtrl.dispose();
    _fotoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final user = ref.read(authProvider).user!;
    final fotoUrl = _fotoUrlCtrl.text.trim();
    await ref.read(authProvider.notifier).updateProfile(
      user.copyWith(
        nome: _nomeCtrl.text.trim(),
        apelido: _apelidoCtrl.text.trim().isEmpty ? null : _apelidoCtrl.text.trim(),
        clearApelido: _apelidoCtrl.text.trim().isEmpty,
        posicaoPrincipal: _posicaoPrincipal,
        clearPosicao: _posicaoPrincipal == null,
        fotoUrl: fotoUrl.isEmpty ? null : fotoUrl,
        clearFoto: fotoUrl.isEmpty,
        avatar: _avatarSelecionado,
        clearAvatar: _avatarSelecionado == null,
      ),
    );
    if (mounted) {
      setState(() { _editMode = false; _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado!'), backgroundColor: AppColors.confirmed));
    }
  }

  void _cancelar() {
    final user = ref.read(authProvider).user!;
    _nomeCtrl.text = user.nome;
    _apelidoCtrl.text = user.apelido ?? '';
    _fotoUrlCtrl.text = user.fotoUrl ?? '';
    setState(() {
      _editMode = false;
      _posicaoPrincipal = user.posicaoPrincipal;
      _avatarSelecionado = user.avatar;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja sair da conta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
            child: const Text('Sair', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final colors = ref.watch(themeConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          if (!_editMode)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editMode = true),
            ),
          if (_editMode) ...[
            TextButton(
              onPressed: _cancelar,
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: _isLoading ? null : _salvar,
              child: _isLoading
                  ? const SizedBox(height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      body: ListView(
        children: [
          _AvatarHeader(
            user: user,
            editMode: _editMode,
            avatarSelecionado: _avatarSelecionado,
            fotoUrlCtrl: _fotoUrlCtrl,
            onAvatarTap: _editMode ? () => _mostrarEscolhaAvatar(context) : null,
          ),
          const SizedBox(height: 8),
          if (_editMode)
            _EditForm(
              nomeCtrl: _nomeCtrl,
              apelidoCtrl: _apelidoCtrl,
              posicaoPrincipal: _posicaoPrincipal,
              onPosicaoChanged: (p) => setState(() => _posicaoPrincipal = p),
            )
          else
            _InfoView(user: user),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.primary),
            title: const Text('Alterar senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _mostrarAlterarSenha(context),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
            title: const Text('Personalizar tema'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 20, height: 20,
                decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ]),
            onTap: () => _mostrarTema(context),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: AppColors.error),
            title: const Text('Sair da conta', style: TextStyle(color: AppColors.error)),
            onTap: _logout,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _mostrarEscolhaAvatar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Escolher avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _avatares.map((a) => GestureDetector(
                onTap: () {
                  setState(() => _avatarSelecionado = a);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: _avatarSelecionado == a
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _avatarSelecionado == a ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(child: Text(a, style: const TextStyle(fontSize: 28))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() => _avatarSelecionado = null);
                Navigator.pop(context);
              },
              child: const Text('Remover avatar'),
            ),
          ]),
        ),
      ),
    );
  }

  void _mostrarAlterarSenha(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Alterar senha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: 'Senha atual'), obscureText: true),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Nova senha'), obscureText: true),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Confirmar nova senha'), obscureText: true),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Senha alterada (mock)'), backgroundColor: AppColors.confirmed));
            },
            child: const Text('Alterar senha'),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _mostrarTema(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _TemaBottomSheet(),
    );
  }
}

// ── Avatar Header ──────────────────────────────────────────────────────────────

class _AvatarHeader extends StatelessWidget {
  final UserModel user;
  final bool editMode;
  final String? avatarSelecionado;
  final TextEditingController fotoUrlCtrl;
  final VoidCallback? onAvatarTap;

  const _AvatarHeader({
    required this.user,
    required this.editMode,
    required this.avatarSelecionado,
    required this.fotoUrlCtrl,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: Stack(
            children: [
              _buildAvatar(),
              if (editMode)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
        if (editMode) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 260,
            child: TextField(
              controller: fotoUrlCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'URL da foto (opcional)',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                prefixIcon: const Icon(Icons.link, color: Colors.white70, size: 18),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Text(user.nomeExibicao,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          Text('@${user.username}', style: const TextStyle(color: Colors.white70)),
          if (user.posicaoPrincipal != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(user.posicaoPrincipal!,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ]),
    );
  }

  Widget _buildAvatar() {
    if (user.fotoUrl != null && user.fotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: NetworkImage(user.fotoUrl!),
        backgroundColor: Colors.white,
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }
    if (avatarSelecionado != null) {
      return CircleAvatar(
        radius: 44,
        backgroundColor: Colors.white,
        child: Text(avatarSelecionado!, style: const TextStyle(fontSize: 36)),
      );
    }
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white,
      child: Text(
        (user.apelido ?? user.nome).isNotEmpty ? (user.apelido ?? user.nome)[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Info View ──────────────────────────────────────────────────────────────────

class _InfoView extends StatelessWidget {
  final UserModel user;
  const _InfoView({required this.user});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _Row(Icons.person_outline, 'Nome', user.nome),
          const Divider(),
          _Row(Icons.sports_soccer, 'Apelido', user.apelido ?? '—'),
          const Divider(),
          _Row(Icons.email_outlined, 'E-mail', user.email),
          if (user.posicaoPrincipal != null) ...[
            const Divider(),
            _Row(Icons.shield_outlined, 'Posição', user.posicaoPrincipal!),
          ],
        ]),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    ]),
  );
}

// ── Edit Form ──────────────────────────────────────────────────────────────────

class _EditForm extends StatelessWidget {
  final TextEditingController nomeCtrl;
  final TextEditingController apelidoCtrl;
  final String? posicaoPrincipal;
  final ValueChanged<String?> onPosicaoChanged;

  const _EditForm({
    required this.nomeCtrl,
    required this.apelidoCtrl,
    required this.posicaoPrincipal,
    required this.onPosicaoChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(
        controller: nomeCtrl,
        decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person_outline)),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: apelidoCtrl,
        decoration: const InputDecoration(
          labelText: 'Apelido (opcional)',
          prefixIcon: Icon(Icons.sports_soccer),
        ),
      ),
      const SizedBox(height: 20),
      const Text('Posição (opcional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _posicoes.map((p) => ChoiceChip(
          label: Text(p, style: TextStyle(
            fontSize: 13,
            color: posicaoPrincipal == p ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          )),
          selected: posicaoPrincipal == p,
          selectedColor: AppColors.primary,
          onSelected: (_) => onPosicaoChanged(posicaoPrincipal == p ? null : p),
        )).toList(),
      ),
      const SizedBox(height: 8),
    ]),
  );
}

// ── Tema Bottom Sheet ──────────────────────────────────────────────────────────

class _TemaBottomSheet extends ConsumerWidget {
  const _TemaBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(themeConfigProvider);
    final notifier = ref.read(themeConfigProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Personalizar tema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        const Text('Cor principal', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: AppThemeConfig.presets.map((preset) => GestureDetector(
            onTap: () => notifier.setPreset(preset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: preset.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: config.primary == preset.primary ? Colors.black54 : Colors.transparent,
                  width: 3,
                ),
                boxShadow: config.primary == preset.primary
                    ? [BoxShadow(color: preset.primary.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)]
                    : [],
              ),
              child: config.primary == preset.primary
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          )).toList(),
        ),
        const SizedBox(height: 16),
        if (AppThemeConfig.presets.any((p) => p.primary == config.primary))
          Text(
            AppThemeConfig.presets.firstWhere((p) => p.primary == config.primary).nome,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        const SizedBox(height: 8),
      ]),
    );
  }
}
