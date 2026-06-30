import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _keyUserId = 'mock_user_id';
  static const _keyUserName = 'mock_user_name';
  static const _keyUserEmail = 'mock_user_email';
  static const _keyUserUsername = 'mock_user_username';
  static const _keyUserApelido = 'mock_user_apelido';
  static const _keyPosicaoPrincipal = 'mock_posicao_principal';
  static const _keyIsLoggedIn = 'mock_is_logged_in';
  static const _keySavedLogin = 'mock_saved_login';
  static const _keySavedPassword = 'mock_saved_password';
  static const _keyRememberMe = 'mock_remember_me';

  static Future<void> saveSession({
    required int userId,
    required String nome,
    required String email,
    required String username,
    String? apelido,
    String? posicaoPrincipal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUserName, nome);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserUsername, username);
    if (apelido != null) await prefs.setString(_keyUserApelido, apelido);
    if (posicaoPrincipal != null) await prefs.setString(_keyPosicaoPrincipal, posicaoPrincipal);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyIsLoggedIn) ?? false)) return null;
    return {
      'id': prefs.getInt(_keyUserId) ?? 1,
      'nome': prefs.getString(_keyUserName) ?? '',
      'email': prefs.getString(_keyUserEmail) ?? '',
      'username': prefs.getString(_keyUserUsername) ?? '',
      'apelido': prefs.getString(_keyUserApelido),
      'posicao_principal': prefs.getString(_keyPosicaoPrincipal) ?? 'Meio-campo',
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserUsername);
    await prefs.remove(_keyUserApelido);
    await prefs.remove(_keyPosicaoPrincipal);
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  static Future<void> saveCredentials(String login, String senha) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedLogin, login);
    await prefs.setString(_keySavedPassword, senha);
    await prefs.setBool(_keyRememberMe, true);
  }

  static Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyRememberMe) ?? false)) return null;
    final login = prefs.getString(_keySavedLogin);
    final senha = prefs.getString(_keySavedPassword);
    if (login == null || senha == null) return null;
    return {'login': login, 'senha': senha};
  }

  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedLogin);
    await prefs.remove(_keySavedPassword);
    await prefs.setBool(_keyRememberMe, false);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }
}
