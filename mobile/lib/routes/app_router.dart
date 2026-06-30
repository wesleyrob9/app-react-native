import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/grupos/screens/grupos_list_screen.dart';
import '../features/grupos/screens/grupo_detail_screen.dart';
import '../features/grupos/screens/criar_grupo_screen.dart';
import '../features/grupos/screens/entrar_grupo_screen.dart';
import '../features/grupos/screens/membros_screen.dart';
import '../features/grupos/screens/pendentes_screen.dart';
import '../features/eventos/screens/eventos_list_screen.dart';
import '../features/eventos/screens/evento_detail_screen.dart';
import '../features/eventos/screens/criar_evento_screen.dart';
import '../features/eventos/screens/participantes_screen.dart';
import '../features/sorteio/screens/config_sorteio_screen.dart';
import '../features/sorteio/screens/resultado_sorteio_screen.dart';
import '../features/avaliacoes/screens/avaliacoes_screen.dart';
import '../features/notificacoes/screens/notificacoes_screen.dart';
import '../features/perfil/screens/perfil_screen.dart';

final _routerKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _routerKey,
    initialLocation: '/grupos',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isLoggedIn = authState.isLoggedIn;
      final path = state.matchedLocation;
      final isAuthRoute = path.startsWith('/login') ||
          path.startsWith('/registro') ||
          path.startsWith('/esqueci-senha');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/grupos';
      return null;
    },
    routes: [
      // Auth
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/esqueci-senha', builder: (_, __) => const ForgotPasswordScreen()),

      // Grupos
      GoRoute(path: '/grupos', builder: (_, __) => const GruposListScreen()),
      GoRoute(path: '/grupos/criar', builder: (_, __) => const CriarGrupoScreen()),
      GoRoute(path: '/grupos/entrar', builder: (_, __) => const EntrarGrupoScreen()),
      GoRoute(
        path: '/grupos/:id',
        builder: (_, state) => GrupoDetailScreen(grupoId: int.parse(state.pathParameters['id']!)),
        routes: [
          GoRoute(
            path: 'membros',
            builder: (_, state) => MembrosScreen(grupoId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'pendentes',
            builder: (_, state) => PendentesScreen(grupoId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'avaliacoes',
            builder: (_, state) => AvaliacoesScreen(grupoId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'eventos',
            builder: (_, state) => EventosListScreen(grupoId: int.parse(state.pathParameters['id']!)),
            routes: [
              GoRoute(
                path: 'criar',
                builder: (_, state) => CriarEventoScreen(grupoId: int.parse(state.pathParameters['id']!)),
              ),
              GoRoute(
                path: ':eid',
                builder: (_, state) => EventoDetailScreen(
                  grupoId: int.parse(state.pathParameters['id']!),
                  eventoId: int.parse(state.pathParameters['eid']!),
                ),
                routes: [
                  GoRoute(
                    path: 'participantes',
                    builder: (_, state) => ParticipantesScreen(
                      grupoId: int.parse(state.pathParameters['id']!),
                      eventoId: int.parse(state.pathParameters['eid']!),
                    ),
                  ),
                  GoRoute(
                    path: 'sorteio',
                    builder: (_, state) => ConfigSorteioScreen(
                      grupoId: int.parse(state.pathParameters['id']!),
                      eventoId: int.parse(state.pathParameters['eid']!),
                    ),
                  ),
                  GoRoute(
                    path: 'resultado',
                    builder: (_, state) => ResultadoSorteioScreen(
                      grupoId: int.parse(state.pathParameters['id']!),
                      eventoId: int.parse(state.pathParameters['eid']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Perfil e Notificações
      GoRoute(path: '/perfil', builder: (_, __) => const PerfilScreen()),
      GoRoute(path: '/notificacoes', builder: (_, __) => const NotificacoesScreen()),
    ],
  );
});
