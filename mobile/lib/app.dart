import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_config.dart';
import 'routes/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeConfig = ref.watch(themeConfigProvider);

    return MaterialApp.router(
      title: 'Fut Grupos',
      theme: AppTheme.fromConfig(themeConfig),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
