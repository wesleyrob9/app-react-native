import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Paleta de cores de um preset de tema
class ThemePreset {
  final String nome;
  final Color primary;
  final Color primaryLight;
  final Color accent;

  const ThemePreset({
    required this.nome,
    required this.primary,
    required this.primaryLight,
    required this.accent,
  });
}

/// Configuração ativa do tema — contém o preset escolhido
class AppThemeConfig {
  final Color primary;
  final Color primaryLight;
  final Color accent;

  const AppThemeConfig({
    required this.primary,
    required this.primaryLight,
    required this.accent,
  });

  /// Paletas disponíveis para escolha
  static const List<ThemePreset> presets = [
    ThemePreset(
      nome: 'Gramado (padrão)',
      primary: Color(0xFF1B5E20),
      primaryLight: Color(0xFF4CAF50),
      accent: Color(0xFFFFB300),
    ),
    ThemePreset(
      nome: 'Noturno Azul',
      primary: Color(0xFF0D47A1),
      primaryLight: Color(0xFF1976D2),
      accent: Color(0xFFFFD600),
    ),
    ThemePreset(
      nome: 'Vermelho Fogo',
      primary: Color(0xFFB71C1C),
      primaryLight: Color(0xFFE53935),
      accent: Color(0xFFFFB300),
    ),
    ThemePreset(
      nome: 'Roxo Arena',
      primary: Color(0xFF4A148C),
      primaryLight: Color(0xFF7B1FA2),
      accent: Color(0xFFFFD600),
    ),
    ThemePreset(
      nome: 'Laranja Gol',
      primary: Color(0xFFE65100),
      primaryLight: Color(0xFFF57C00),
      accent: Color(0xFF1B5E20),
    ),
    ThemePreset(
      nome: 'Preto Clássico',
      primary: Color(0xFF212121),
      primaryLight: Color(0xFF424242),
      accent: Color(0xFFFFB300),
    ),
  ];

  static const AppThemeConfig defaultConfig = AppThemeConfig(
    primary: Color(0xFF1B5E20),
    primaryLight: Color(0xFF4CAF50),
    accent: Color(0xFFFFB300),
  );

  AppThemeConfig copyWith({Color? primary, Color? primaryLight, Color? accent}) =>
      AppThemeConfig(
        primary: primary ?? this.primary,
        primaryLight: primaryLight ?? this.primaryLight,
        accent: accent ?? this.accent,
      );
}

/// Provider que mantém o tema ativo e permite trocar
class ThemeConfigNotifier extends StateNotifier<AppThemeConfig> {
  ThemeConfigNotifier() : super(AppThemeConfig.defaultConfig);

  void setPreset(ThemePreset preset) {
    state = AppThemeConfig(
      primary: preset.primary,
      primaryLight: preset.primaryLight,
      accent: preset.accent,
    );
  }
}

final themeConfigProvider = StateNotifierProvider<ThemeConfigNotifier, AppThemeConfig>(
  (_) => ThemeConfigNotifier(),
);
