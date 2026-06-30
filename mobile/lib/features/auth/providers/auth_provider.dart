import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/mock/mock_data.dart';

// Credenciais mock válidas
const _mockCredentials = [
  {'login': 'xavs10', 'senha': '123456', 'userId': 1},
  {'login': 'wesley@email.com', 'senha': '123456', 'userId': 1},
  {'login': 'carlao7', 'senha': '123456', 'userId': 2},
];

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;
  AuthState copyWith({UserModel? user, bool? isLoading, String? error, bool clearUser = false}) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    final session = await AuthStorage.getSession();
    if (session != null) {
      final user = UserModel(
        id: session['id'] as int,
        nome: session['nome'] as String,
        email: session['email'] as String,
        username: session['username'] as String,
        apelido: session['apelido'] as String?,
        posicaoPrincipal: session['posicao_principal'] as String?,
      );
      state = AuthState(user: user);
    } else {
      state = const AuthState();
    }
  }

  Future<bool> login(String login, String senha, {bool rememberMe = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 800));

    final normalizedLogin = login.trim().toLowerCase();
    final cred = _mockCredentials.firstWhere(
      (c) => c['login'] == normalizedLogin && c['senha'] == senha,
      orElse: () => {},
    );

    if (cred.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Usuario ou senha incorretos');
      return false;
    }

    final userId = cred['userId'] as int;
    final user = MockData.users.firstWhere((u) => u.id == userId);

    await AuthStorage.saveSession(
      userId: user.id,
      nome: user.nome,
      email: user.email,
      username: user.username,
      apelido: user.apelido,
      posicaoPrincipal: user.posicaoPrincipal,
    );

    if (rememberMe) {
      await AuthStorage.saveCredentials(login, senha);
    } else {
      await AuthStorage.clearCredentials();
    }

    state = AuthState(user: user);
    return true;
  }

  Future<bool> register({
    required String nome,
    required String apelido,
    required String email,
    required String username,
    required String senha,
    String? posicaoPrincipal,
    String? posicaoSecundaria,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 1000));

    final user = UserModel(
      id: 99,
      nome: nome,
      apelido: apelido.isEmpty ? null : apelido,
      email: email,
      username: username,
      posicaoPrincipal: posicaoPrincipal,
      posicaoSecundaria: posicaoSecundaria,
    );

    await AuthStorage.saveSession(
      userId: user.id,
      nome: user.nome,
      email: user.email,
      username: user.username,
      apelido: user.apelido,
      posicaoPrincipal: user.posicaoPrincipal,
    );

    state = AuthState(user: user);
    return true;
  }

  Future<void> updateProfile(UserModel updated) async {
    await AuthStorage.saveSession(
      userId: updated.id,
      nome: updated.nome,
      email: updated.email,
      username: updated.username,
      apelido: updated.apelido,
      posicaoPrincipal: updated.posicaoPrincipal,
    );
    state = AuthState(user: updated);
  }

  Future<void> logout() async {
    await AuthStorage.clearSession();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
