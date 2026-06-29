# SPEC - ESTRUTURA DO PROJETO (Monorepo)

**Projeto:** Sistema de Gerenciamento de Grupos de Futebol Amador  
**Decisao:** Monorepo com subpastas separadas por camada (backend, mobile, web)  
**Data:** 2026-06-29

---

## 1. DECISAO ARQUITETURAL

O projeto adota a abordagem **monorepo** — um unico repositorio Git contendo os tres subprojetos (backend, mobile, web) e a documentacao tecnica. Cada subprojeto e independente em dependencias mas compartilha o mesmo versionamento e historico.

### 1.1 Justificativas

| Fator | Beneficio |
|-------|-----------|
| Repositorio unico | Um `git log`, um historico, uma source of truth |
| Specs junto ao codigo | Documentacao sempre acessivel para a IA e desenvolvedores |
| API compartilhada | Mobile e web consomem a mesma API; mudancas ficam sincronizadas |
| Simplicidade | Sem overhead de gerenciar multiplos repos para projeto de escala pequena/media |
| Deploy independente | Cada subpasta tem seu proprio deploy; backend na VPS, mobile nas lojas, web em hosting |

### 1.2 Regra de Isolamento

Cada subprojeto mantem suas proprias dependencias:

| Subprojeto | Gerenciador | Arquivo |
|------------|-------------|---------|
| `backend/` | pip (Python) | `requirements.txt` |
| `mobile/` | pub (Dart/Flutter) | `pubspec.yaml` |
| `web/` | npm/yarn (Node) | `package.json` |

> **PROIBIDO:** Instalar dependencias Python no mobile/web ou vice-versa. Nao existe `pubspec.yaml` ou `package.json` na raiz.

---

## 2. ESTRUTURA DE PASTAS

```
app-react-native/
│
├── backend/                        # API Flask (Python)
│   ├── app/
│   │   ├── __init__.py             # Application Factory (create_app)
│   │   ├── config.py               # Configuracoes e variaveis de ambiente
│   │   ├── database.py             # SQLAlchemy + Migrate init
│   │   ├── socketio_setup.py       # Flask-SocketIO init
│   │   │
│   │   ├── models/                 # Models SQLAlchemy
│   │   │   ├── __init__.py         # Importa todos os models
│   │   │   ├── usuario.py          # Usuario + PerfilJogador
│   │   │   ├── grupo.py            # Grupo + GrupoMembro + AvaliacaoJogador
│   │   │   ├── evento.py           # Evento + EventoParticipante
│   │   │   ├── sorteio.py          # Sorteio + Time + TimeJogador
│   │   │   ├── historico_avaliacao.py
│   │   │   ├── notificacao.py
│   │   │   └── password_reset.py
│   │   │
│   │   ├── blueprints/             # Controladores REST por dominio
│   │   │   ├── auth/               # Registro, Login, Perfil, Senha
│   │   │   │   ├── __init__.py
│   │   │   │   └── routes.py
│   │   │   ├── grupos/             # Grupos, Membros, Avaliacoes
│   │   │   │   ├── __init__.py
│   │   │   │   └── routes.py
│   │   │   ├── eventos/            # Eventos, Presenca
│   │   │   │   ├── __init__.py
│   │   │   │   └── routes.py
│   │   │   └── sorteador/          # Sorteio, Times
│   │   │       ├── __init__.py
│   │   │       └── routes.py
│   │   │
│   │   ├── services/               # Logica de negocio
│   │   │   ├── auth_service.py
│   │   │   ├── grupo_service.py
│   │   │   ├── evento_service.py
│   │   │   └── sorteio_service.py
│   │   │
│   │   ├── utils/                  # Utilitarios compartilhados
│   │   │   ├── jwt_utils.py
│   │   │   └── decorators.py
│   │   │
│   │   └── sockets/                # WebSocket handlers
│   │       └── sorteio_live.py
│   │
│   ├── migrations/                 # Flask-Migrate (Alembic)
│   ├── wsgi.py                     # Ponto de entrada Gunicorn
│   ├── requirements.txt            # Dependencias Python
│   └── .env                        # Variaveis de ambiente (NAO committar)
│
├── mobile/                         # Flutter (Dart)
│   ├── lib/
│   │   ├── screens/                # Telas do app (Pages/Screens)
│   │   ├── widgets/                # Widgets reutilizaveis
│   │   ├── providers/              # Riverpod providers (estado reativo)
│   │   ├── services/               # Chamadas API (http/dio)
│   │   ├── models/                 # Modelos Dart (DTOs)
│   │   ├── routes/                 # GoRouter / navegacao
│   │   ├── utils/                  # Helpers, constantes
│   │   └── main.dart               # Entry point
│   ├── assets/                     # Imagens, fontes, avatares
│   ├── pubspec.yaml                # Dependencias Dart/Flutter
│   └── android/ ios/               # Plataformas nativas (gerado pelo Flutter)
│
├── web/                            # Frontend Web (fase futura)
│   ├── src/
│   └── package.json
│
├── docs/                           # Especificacoes tecnicas
│   ├── geral.md                    # Arquitetura master
│   ├── requisitos.md               # Requisitos funcionais e nao funcionais
│   ├── spec-banco-de-dados.md      # Modelagem completa do banco
│   ├── spec-auth.md                # Modulo de autenticacao
│   └── spec-estrutura-projeto.md   # Este arquivo
│
├── .gitignore                      # Exclusoes globais
└── README.md                       # Visao geral do projeto
```

---

## 3. REGRAS DE ORGANIZACAO

### 3.1 Backend (`backend/`)

| Regra | Descricao |
|-------|-----------|
| Application Factory | `create_app()` em `app/__init__.py`, nunca `app = Flask()` global |
| Um Blueprint por dominio | `auth/`, `grupos/`, `eventos/`, `sorteador/` |
| Service Layer | Logica de negocio em `services/`, nunca direto nas routes |
| Models separados | Um arquivo por dominio, todos importados no `models/__init__.py` |
| Respostas JSON padrao | Sucesso: `{"message": "...", "data": {...}}` / Erro: `{"error": "..."}` |
| Sem SQL bruto | Sempre via SQLAlchemy ORM |

### 3.2 Mobile (`mobile/`)

| Regra | Descricao |
|-------|-----------|
| Flutter SDK | Usar widgets nativos e Material Design 3 |
| Riverpod para estado | Providers para logica de negocio, nenhuma chamada HTTP direto no widget |
| Services para API | Camada dedicada para chamadas HTTP (dio/http) |
| socket_io_client para WebSocket | Conexao aberta apenas na tela de sorteio ao vivo |
| Desconectar ao sair | Fechar WebSocket ao sair da tela ou minimizar o app (WidgetsBindingObserver) |

### 3.3 Web (`web/`)

| Regra | Descricao |
|-------|-----------|
| Fase posterior | Sera construido apos o mobile estar funcional |
| Mesma API | Consome os mesmos endpoints do `backend/` |
| Stack a definir | Vue.js, React ou outro — decisao futura |

### 3.4 Docs (`docs/`)

| Regra | Descricao |
|-------|-----------|
| Specs versionadas | Toda spec fica em `docs/` e e commitada junto ao codigo |
| Nomenclatura | `spec-<dominio>.md` (ex: `spec-auth.md`, `spec-banco-de-dados.md`) |
| Referencia cruzada | Specs devem referenciar outras specs quando houver dependencia |
| Fonte da verdade | Em caso de duvida, a spec mais recente prevalece sobre o codigo |

---

## 4. .gitignore (RAIZ)

```gitignore
# Python / Backend
backend/.env
backend/__pycache__/
backend/app/__pycache__/
backend/**/__pycache__/
backend/*.pyc
backend/venv/
backend/.venv/

# Flutter / Mobile
mobile/.dart_tool/
mobile/.packages
mobile/build/
mobile/.flutter-plugins
mobile/.flutter-plugins-dependencies
mobile/pubspec.lock

# Node / Web
web/node_modules/
*.log

# IDEs
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Build
web/dist/
web/build/
```

---

## 5. ORDEM DE CONSTRUCAO DO PROJETO

| Fase | O que construir | Dependencia |
|------|----------------|-------------|
| 1 | `backend/` — Models + Migration inicial | spec-banco-de-dados.md |
| 2 | `backend/` — Modulo Auth (registro, login, JWT, perfil) | spec-auth.md |
| 3 | `backend/` — Modulo Grupos (CRUD, membros, avaliacoes) | spec futura |
| 4 | `backend/` — Modulo Eventos (CRUD, presenca) | spec futura |
| 5 | `backend/` — Modulo Sorteio (algoritmo, persistencia) | spec futura |
| 6 | `backend/` — Modulo Sorteio ao Vivo (WebSocket) | spec futura |
| 7 | `backend/` — Modulo Notificacoes | spec futura |
| 8 | `mobile/` — Setup Flutter + Riverpod + Navegacao + Tela de Auth | backend fase 2 pronta |
| 9 | `mobile/` — Telas de Grupos, Eventos, Sorteio | backend fases 3-6 prontas |
| 10 | `web/` — Frontend web | backend completo |

---

## 6. COMUNICACAO ENTRE CAMADAS

```
mobile/ (Flutter)        ──── REST (JSON) ────►  backend/ (Flask API)
                         ◄─── WebSocket ──────   (Flask-SocketIO)

web/ (Frontend Web)      ──── REST (JSON) ────►  backend/ (Flask API)
                         ◄─── WebSocket ──────   (Flask-SocketIO)
```

- **Base URL da API:** Configuravel via variavel de ambiente em cada client
  - Desenvolvimento: `http://localhost:5000/api`
  - Producao: `https://api.meudominio.com.br/api`
- **WebSocket:** Mesma URL base, protocolo `ws://` / `wss://`
- **Formato:** Todas as respostas em JSON, UTF-8
- **Autenticacao:** Header `Authorization: Bearer <access_token>` em rotas protegidas
