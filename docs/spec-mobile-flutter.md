# SPEC - MOBILE FLUTTER

**Projeto:** Sistema de Gerenciamento de Grupos de Futebol Amador  
**Stack:** Flutter 3.x + Dart 3.x + Riverpod 2 + Dio + GoRouter  
**Baseado em:** `geral.md`, `requisitos.md`, `spec-auth.md`, `spec-estrutura-projeto.md`  
**Data:** 2026-06-29

---

## 1. VISAO GERAL

App mobile nativo (Android + iOS) construido com Flutter. Consome a API REST Flask do backend via HTTP (Dio) e futuramente WebSocket (socket_io_client) para o sorteio ao vivo.

### 1.1 Principios

- **Feature-first:** Cada modulo do negocio (auth, grupos, eventos, sorteio, notificacoes) e uma pasta isolada com seus proprios models, repositories, providers e screens
- **Unidirectional data flow:** Screen observa Provider -> Provider chama Repository -> Repository chama ApiClient -> ApiClient faz HTTP
- **Sem logica na UI:** Screens sao widgets que observam providers. Nenhuma chamada HTTP ou manipulacao de dados no corpo do widget
- **Imutabilidade:** Models gerados com Freezed (imutaveis, copyWith, fromJson/toJson)

---

## 2. ARQUITETURA

### 2.1 Fluxo de Dados

```
Screen (Widget)
    | ref.watch(provider)
    v
Provider (Riverpod)
    | chama metodo
    v
Repository (camada de dados)
    | usa
    v
ApiClient (Dio + AuthInterceptor)
    | HTTP request
    v
Backend Flask (/api/...)
```

### 2.2 Responsabilidades de Cada Camada

| Camada | Responsabilidade | Exemplo |
|--------|-----------------|---------|
| **Screen** | Renderizar UI, observar providers, disparar acoes | `LoginScreen` observa `authProvider`, chama `ref.read(authProvider.notifier).login()` |
| **Provider** | Gerenciar estado reativo, orquestrar chamadas | `authProvider` mantem `AsyncValue<User?>`, chama `AuthRepository.login()` |
| **Repository** | Traduzir chamadas HTTP em objetos Dart | `AuthRepository.login()` faz POST, converte JSON em `AuthResponse` |
| **Model** | Representar dados (DTOs imutaveis) | `User`, `Grupo`, `Evento` com Freezed |
| **ApiClient** | Configurar Dio, interceptors, base URL | Injeta `Authorization: Bearer`, faz refresh automatico |

---

## 3. ESTRUTURA DE PASTAS

```
mobile/
├── lib/
│   ├── main.dart                         # Entry point: ProviderScope + App
│   ├── app.dart                          # MaterialApp.router, tema, GoRouter
│   │
│   ├── core/                             # Infraestrutura compartilhada
│   │   ├── config/
│   │   │   └── api_config.dart           # Base URL, timeouts
│   │   ├── network/
│   │   │   ├── api_client.dart           # Dio singleton provider
│   │   │   └── auth_interceptor.dart     # Injeta JWT, refresh automatico
│   │   ├── storage/
│   │   │   └── secure_storage.dart       # flutter_secure_storage wrapper
│   │   ├── theme/
│   │   │   ├── app_theme.dart            # ThemeData Material 3
│   │   │   └── app_colors.dart           # Paleta de cores
│   │   ├── providers/
│   │   │   └── dio_provider.dart         # Provider global do Dio
│   │   └── widgets/
│   │       ├── loading_widget.dart       # Spinner padrao
│   │       ├── error_widget.dart         # Tela de erro com retry
│   │       └── empty_widget.dart         # Estado vazio
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── models/
│   │   │   │   ├── user.dart             # Freezed: id, nome, apelido, email, username
│   │   │   │   ├── user_profile.dart     # Freezed: foto, avatar, posicoes
│   │   │   │   └── auth_response.dart    # Freezed: user + tokens
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart  # POST /registro, /login, /refresh, GET/PUT /me
│   │   │   ├── providers/
│   │   │   │   ├── auth_provider.dart    # Estado de autenticacao (logado/deslogado)
│   │   │   │   └── user_provider.dart    # Dados do usuario logado
│   │   │   └── screens/
│   │   │       ├── login_screen.dart
│   │   │       ├── register_screen.dart
│   │   │       ├── forgot_password_screen.dart
│   │   │       └── profile_screen.dart
│   │   │
│   │   ├── grupos/
│   │   │   ├── models/
│   │   │   │   ├── grupo.dart            # Freezed: id, nome, descricao, cidade, codigo
│   │   │   │   └── membro.dart           # Freezed: usuario_id, nome, papel, estrelas
│   │   │   ├── repositories/
│   │   │   │   └── grupo_repository.dart
│   │   │   ├── providers/
│   │   │   │   ├── grupos_provider.dart       # Lista meus grupos
│   │   │   │   ├── grupo_detail_provider.dart # Detalhes + membros
│   │   │   │   └── pendentes_provider.dart    # Solicitacoes pendentes
│   │   │   └── screens/
│   │   │       ├── grupos_list_screen.dart
│   │   │       ├── grupo_detail_screen.dart
│   │   │       ├── criar_grupo_screen.dart
│   │   │       ├── entrar_grupo_screen.dart
│   │   │       └── membros_screen.dart
│   │   │
│   │   ├── eventos/
│   │   │   ├── models/
│   │   │   │   ├── evento.dart
│   │   │   │   └── participante.dart
│   │   │   ├── repositories/
│   │   │   │   └── evento_repository.dart
│   │   │   ├── providers/
│   │   │   │   ├── eventos_provider.dart
│   │   │   │   └── participantes_provider.dart
│   │   │   └── screens/
│   │   │       ├── eventos_list_screen.dart
│   │   │       ├── evento_detail_screen.dart
│   │   │       ├── criar_evento_screen.dart
│   │   │       └── participantes_screen.dart
│   │   │
│   │   ├── sorteio/
│   │   │   ├── models/
│   │   │   │   ├── sorteio.dart
│   │   │   │   ├── time_result.dart
│   │   │   │   └── jogador_sorteado.dart
│   │   │   ├── repositories/
│   │   │   │   └── sorteio_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── sorteio_provider.dart
│   │   │   └── screens/
│   │   │       ├── config_sorteio_screen.dart
│   │   │       ├── resultado_sorteio_screen.dart
│   │   │       └── sorteio_live_screen.dart    # Futuro: WebSocket
│   │   │
│   │   ├── avaliacoes/
│   │   │   ├── models/
│   │   │   │   └── avaliacao.dart
│   │   │   ├── repositories/
│   │   │   │   └── avaliacao_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── avaliacoes_provider.dart
│   │   │   └── screens/
│   │   │       └── avaliacoes_screen.dart
│   │   │
│   │   └── notificacoes/
│   │       ├── models/
│   │       │   └── notificacao.dart
│   │       ├── repositories/
│   │       │   └── notificacao_repository.dart
│   │       ├── providers/
│   │       │   ├── notificacoes_provider.dart
│   │       │   └── badge_provider.dart        # Contagem nao lidas (badge)
│   │       └── screens/
│   │           └── notificacoes_screen.dart
│   │
│   └── routes/
│       └── app_router.dart                    # GoRouter + auth guard
│
├── assets/
│   ├── images/
│   └── avatars/
│
├── pubspec.yaml
├── analysis_options.yaml
└── android/ ios/                              # Plataformas nativas
```

---

## 4. DEPENDENCIAS (pubspec.yaml)

### 4.1 Dependencias Principais

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Estado
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # HTTP
  dio: ^5.7.0

  # Navegacao
  go_router: ^14.6.0

  # Storage seguro
  flutter_secure_storage: ^9.2.3

  # Models imutaveis
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

  # UI
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.16
  cached_network_image: ^3.4.1

  # Utilidades
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

  # Geradores de codigo
  riverpod_generator: ^2.6.2
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  build_runner: ^2.4.13
```

### 4.2 Justificativas

| Pacote | Por que | Alternativa descartada |
|--------|---------|----------------------|
| `flutter_riverpod` | Estado reativo, type-safe, auto-dispose, sem BuildContext | BLoC (muito boilerplate), Provider (menos poderoso) |
| `dio` | Interceptors para JWT refresh automatico, cancel tokens | http (sem interceptors nativos) |
| `go_router` | Declarativo, deep linking, guards de auth | Navigator 2.0 puro (complexo demais) |
| `flutter_secure_storage` | Tokens no Keychain (iOS) / Keystore (Android) | shared_preferences (nao criptografa) |
| `freezed` | Models imutaveis com fromJson, copyWith, ==, hashCode gerados | Escrever manualmente (propenso a erros) |

---

## 5. CORE: DETALHAMENTO

### 5.1 ApiClient (Dio)

```dart
// core/network/api_client.dart
// Dio configurado com:
// - baseUrl: http://10.0.2.2:5000/api (emulador) ou variavel de ambiente
// - connectTimeout: 15s
// - receiveTimeout: 15s
// - contentType: application/json
// - AuthInterceptor adicionado
```

### 5.2 AuthInterceptor

Interceptor do Dio que:

1. **onRequest:** Busca o access_token no SecureStorage e injeta `Authorization: Bearer <token>` em todas as requisicoes (exceto /login, /registro, /refresh)
2. **onError (401):** Captura respostas 401, busca o refresh_token, chama `POST /api/auth/refresh`, salva o novo access_token, e refaz a requisicao original transparentemente
3. **Se refresh falhar:** Limpa tokens, redireciona para LoginScreen

```
Request -> AuthInterceptor.onRequest -> adiciona Bearer
                                            |
Response 200 <-----------------------------+
                                            |
Response 401 -> AuthInterceptor.onError -> chama /refresh
                                            |
                                  sucesso? -> salva novo token -> refaz request
                                  falhou?  -> logout -> LoginScreen
```

### 5.3 SecureStorage

```dart
// core/storage/secure_storage.dart
// Wrapper sobre flutter_secure_storage com metodos:
// - saveTokens(access, refresh)
// - getAccessToken() -> String?
// - getRefreshToken() -> String?
// - clearTokens()
// - hasTokens() -> bool
```

---

## 6. NAVEGACAO (GoRouter)

### 6.1 Estrutura de Rotas

```
/login                              # LoginScreen
/registro                           # RegisterScreen
/esqueci-senha                      # ForgotPasswordScreen

/grupos                             # GruposListScreen (home)
/grupos/criar                       # CriarGrupoScreen
/grupos/entrar                      # EntrarGrupoScreen
/grupos/:id                         # GrupoDetailScreen
/grupos/:id/membros                 # MembrosScreen
/grupos/:id/avaliacoes              # AvaliacoesScreen
/grupos/:id/eventos                 # EventosListScreen
/grupos/:id/eventos/criar           # CriarEventoScreen
/grupos/:id/eventos/:eid            # EventoDetailScreen
/grupos/:id/eventos/:eid/sorteio    # ConfigSorteioScreen
/grupos/:id/eventos/:eid/resultado  # ResultadoSorteioScreen

/perfil                             # ProfileScreen
/notificacoes                       # NotificacoesScreen
```

### 6.2 Auth Guard

```dart
redirect: (context, state) {
  final isLoggedIn = ref.read(authProvider) != null;
  final isAuthRoute = state.matchedLocation.startsWith('/login') ||
                      state.matchedLocation.startsWith('/registro');

  if (!isLoggedIn && !isAuthRoute) return '/login';
  if (isLoggedIn && isAuthRoute) return '/grupos';
  return null;
}
```

---

## 7. FEATURES: MAPEAMENTO API -> FLUTTER

### 7.1 Auth

| Endpoint Backend | Repository Method | Provider |
|-----------------|-------------------|----------|
| `POST /api/auth/registro` | `register()` | `authProvider` |
| `POST /api/auth/login` | `login()` | `authProvider` |
| `POST /api/auth/refresh` | `refresh()` | `AuthInterceptor` (automatico) |
| `GET /api/auth/me` | `getProfile()` | `userProvider` |
| `PUT /api/auth/me` | `updateProfile()` | `userProvider` |
| `PUT /api/auth/alterar-senha` | `changePassword()` | `authProvider` |
| `POST /api/auth/esqueci-senha` | `forgotPassword()` | direto no screen |
| `POST /api/auth/redefinir-senha` | `resetPassword()` | direto no screen |

### 7.2 Grupos

| Endpoint Backend | Repository Method | Provider |
|-----------------|-------------------|----------|
| `POST /api/grupos` | `create()` | `gruposProvider` |
| `GET /api/grupos` | `list()` | `gruposProvider` |
| `GET /api/grupos/:id` | `getById()` | `grupoDetailProvider(id)` |
| `PUT /api/grupos/:id` | `update()` | `grupoDetailProvider(id)` |
| `POST /api/grupos/entrar` | `join()` | `gruposProvider` |
| `GET /api/grupos/:id/membros` | `listMembers()` | `grupoDetailProvider(id)` |
| `GET /api/grupos/:id/pendentes` | `listPending()` | `pendentesProvider(id)` |
| `PUT .../aprovar` | `approve()` | `pendentesProvider(id)` |
| `PUT .../rejeitar` | `reject()` | `pendentesProvider(id)` |
| `PUT .../promover` | `promote()` | `grupoDetailProvider(id)` |
| `PUT .../rebaixar` | `demote()` | `grupoDetailProvider(id)` |
| `DELETE .../membros/:uid` | `removeMember()` | `grupoDetailProvider(id)` |
| `DELETE .../sair` | `leave()` | `gruposProvider` |

### 7.3 Eventos

| Endpoint Backend | Repository Method | Provider |
|-----------------|-------------------|----------|
| `POST .../eventos` | `create()` | `eventosProvider(gid)` |
| `GET .../eventos` | `list()` | `eventosProvider(gid)` |
| `GET .../eventos/:eid` | `getById()` | `eventoDetailProvider(gid, eid)` |
| `PUT .../eventos/:eid` | `update()` | `eventoDetailProvider(gid, eid)` |
| `PUT .../cancelar` | `cancel()` | `eventoDetailProvider(gid, eid)` |
| `PUT .../encerrar` | `closeConfirmations()` | `eventoDetailProvider(gid, eid)` |
| `PUT .../reabrir` | `reopenConfirmations()` | `eventoDetailProvider(gid, eid)` |
| `POST .../presenca` | `respond()` | `participantesProvider(gid, eid)` |
| `GET .../participantes` | `listParticipants()` | `participantesProvider(gid, eid)` |

### 7.4 Sorteio

| Endpoint Backend | Repository Method | Provider |
|-----------------|-------------------|----------|
| `POST .../sorteio` | `create()` | `sorteioProvider(gid, eid)` |
| `GET .../sorteio` | `get()` | `sorteioProvider(gid, eid)` |
| `PUT .../confirmar` | `confirm()` | `sorteioProvider(gid, eid)` |

### 7.5 Avaliacoes

| Endpoint Backend | Repository Method | Provider |
|-----------------|-------------------|----------|
| `GET .../avaliacoes` | `list()` | `avaliacoesProvider(gid)` |
| `GET .../avaliacoes/:uid` | `getByUser()` | `avaliacoesProvider(gid)` |
| `PUT .../avaliacoes/:uid` | `rate()` | `avaliacoesProvider(gid)` |
| `GET .../historico` | `history()` | `avaliacoesProvider(gid)` |

### 7.6 Notificacoes

| Endpoint Backend | Repository Method | Provider |
|-----------------|-------------------|----------|
| `GET /api/notificacoes` | `list()` | `notificacoesProvider` |
| `GET /api/notificacoes/contagem` | `count()` | `badgeProvider` |
| `PUT .../lida` | `markRead()` | `notificacoesProvider` |
| `PUT .../lidas` | `markAllRead()` | `notificacoesProvider` |

---

## 8. TEMA E UI

### 8.1 Design System

- **Base:** Material Design 3 (Material You)
- **Cores:** Definidas em `app_colors.dart`, seedColor verde (futebol)
- **Tipografia:** Google Fonts (Poppins ou Inter)
- **Modo escuro:** Suportado via ThemeData.dark

### 8.2 Telas Principais (wireframe logico)

```
[Login] -> [Meus Grupos (Home)]
                |
                +-> [Detalhes Grupo]
                |       |
                |       +-> [Membros]
                |       +-> [Avaliacoes]
                |       +-> [Eventos]
                |               |
                |               +-> [Detalhes Evento]
                |                       |
                |                       +-> [Participantes]
                |                       +-> [Sorteio]
                |                       +-> [Resultado]
                |
                +-> [Criar Grupo]
                +-> [Entrar no Grupo]

[Perfil] (tab ou drawer)
[Notificacoes] (tab ou icone com badge)
```

---

## 9. REGRAS DE IMPLEMENTACAO

1. **Nenhuma chamada HTTP em widgets.** Sempre via repository chamado por provider
2. **Providers com autoDispose.** Limpar estado quando a tela sair do escopo
3. **Family providers para parametrizados.** Ex: `grupoDetailProvider(id)`, `eventosProvider(grupoId)`
4. **Tratamento de erro padronizado.** `AsyncValue` do Riverpod: `.when(data:, loading:, error:)`
5. **Formularios com validacao local.** Validar antes de enviar para API (mesmas regras da spec-auth)
6. **Refresh token automatico.** AuthInterceptor resolve sem intervencao do usuario
7. **Pull to refresh.** Todas as listas suportam RefreshIndicator
8. **Offline-first nao e escopo.** App requer conexao para funcionar

---

## 10. ORDEM DE IMPLEMENTACAO

| Fase | O que construir | Dependencia |
|------|----------------|-------------|
| 1 | `flutter create`, pubspec.yaml, core/ (Dio, Storage, Theme) | - |
| 2 | Feature auth (models, repository, providers, screens) | core/ |
| 3 | Navegacao (GoRouter + auth guard) | auth |
| 4 | Feature grupos (list, detail, criar, entrar, membros) | auth + nav |
| 5 | Feature avaliacoes | grupos |
| 6 | Feature eventos (list, detail, criar, presenca) | grupos |
| 7 | Feature sorteio (config, resultado) | eventos |
| 8 | Feature notificacoes (list, badge, marcar lida) | auth |
| 9 | Feature sorteio ao vivo (WebSocket) | sorteio + backend WS |
| 10 | Polimento (animacoes, empty states, error states) | tudo |
