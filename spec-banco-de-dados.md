# SPEC - BANCO DE DADOS (Flask + Flask-Migrate/Alembic + PostgreSQL)

**Projeto:** Sistema de Gerenciamento de Grupos de Futebol Amador  
**Stack:** Python (Flask) + Flask-SQLAlchemy + Flask-Migrate + PostgreSQL  
**Baseado em:** `geral.md` (arquitetura) + `requisitos.md` (requisitos funcionais)  
**Data:** 2026-06-29

---

## 1. VISAO GERAL

Este documento especifica a estrutura completa do banco de dados PostgreSQL, incluindo todas as tabelas, relacionamentos, indices e constraints. Serve como guia para a IA gerar os models SQLAlchemy e as migrations via Flask-Migrate (Alembic).

### 1.1 Gaps Identificados e Corrigidos

| # | Gap | Origem | Correcao |
|---|-----|--------|----------|
| 1 | Tabelas `sorteios`, `times`, `time_jogadores` mencionadas mas sem campos detalhados | `geral.md` seção 3.9 | Campos completos definidos nas seções 3.9, 3.10, 3.11 |
| 2 | Tabela `notificacoes` ausente | RF-043 a RF-046, entidade listada na seção 11 | Tabela completa definida na seção 3.12 |
| 3 | Falta `created_at` em `grupo_membros` | Controle de auditoria | Campo adicionado |
| 4 | Falta `created_at` em `avaliacoes_jogador` | Controle de auditoria | Campo adicionado |
| 5 | Falta suporte a cancelamento de evento | RF-019 | Campo `cancelado_em` e `motivo_cancelamento` adicionados em `eventos` |
| 6 | Falta `created_at` em `evento_participantes` | Rastreio de quando confirmou | Campo adicionado |
| 7 | Recuperacao de senha sem mecanismo no banco | RF-003 | Tabela `password_reset_tokens` adicionada (seção 3.13) |
| 8 | Falta mecanismo de convite para grupos | RF-007 implica busca ou convite | Campo `codigo_convite` adicionado em `grupos` (seção 3.3) |
| 9 | Falta `updated_at` em `usuarios` | Controle de alteracao de perfil | Campo adicionado |

---

## 2. CONVENCOES

- **Nomenclatura de tabelas:** snake_case, plural em portugues (ex: `usuarios`, `grupos`)
- **Nomenclatura de colunas:** snake_case (ex: `data_evento`, `usuario_id`)
- **Primary Keys:** `id` SERIAL para tabelas simples; composite keys para tabelas associativas
- **Foreign Keys:** sufixo `_id` referenciando a tabela pai (ex: `grupo_id` -> `grupos.id`)
- **Timestamps:** `TIMESTAMP WITH TIME ZONE` usando `func.now()` do SQLAlchemy
- **Soft Delete:** campo `is_active BOOLEAN DEFAULT TRUE` onde aplicavel
- **Strings/Hashes:** `VARCHAR(n)` com tamanhos adequados
- **Cascade:** `ON DELETE CASCADE` em tabelas filhas dependentes; `ON DELETE RESTRICT` onde a exclusao deve ser impedida
- **Indices:** B-Tree em campos de busca frequente (email, username, grupo_id, evento_id, etc.)

---

## 3. MODELO DE DADOS COMPLETO

### 3.1 Tabela: `usuarios`

Requisitos atendidos: RF-001, RF-002, RF-003

| Campo | Tipo SQLAlchemy | Tipo PostgreSQL | Restricoes | Descricao |
|-------|----------------|-----------------|------------|-----------|
| `id` | `db.Integer` | `SERIAL` | `PRIMARY KEY` | Identificador unico |
| `nome` | `db.String(100)` | `VARCHAR(100)` | `NOT NULL` | Nome completo |
| `apelido` | `db.String(50)` | `VARCHAR(50)` | `NULLABLE` | Nome de guerra no futebol |
| `email` | `db.String(150)` | `VARCHAR(150)` | `UNIQUE, NOT NULL` | E-mail do usuario |
| `username` | `db.String(50)` | `VARCHAR(50)` | `UNIQUE, NOT NULL` | Nick de acesso |
| `senha_hash` | `db.String(255)` | `VARCHAR(255)` | `NOT NULL` | Hash Bcrypt |
| `created_at` | `db.DateTime` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Data de cadastro |
| `updated_at` | `db.DateTime` | `TIMESTAMPTZ` | `DEFAULT NOW(), ON UPDATE NOW()` | Ultima alteracao |
| `is_active` | `db.Boolean` | `BOOLEAN` | `DEFAULT TRUE` | Soft delete |

**Indices:**
- `ix_usuarios_email` UNIQUE em `email`
- `ix_usuarios_username` UNIQUE em `username`

**Relacionamentos SQLAlchemy:**
- `perfil` -> `perfis_jogador` (1:1, uselist=False, back_populates)
- `grupos` -> `grupo_membros` (1:N)
- `eventos_participacao` -> `evento_participantes` (1:N)
- `notificacoes` -> `notificacoes` (1:N)

---

### 3.2 Tabela: `perfis_jogador`

Requisitos atendidos: RF-004

| Campo | Tipo SQLAlchemy | Tipo PostgreSQL | Restricoes | Descricao |
|-------|----------------|-----------------|------------|-----------|
| `usuario_id` | `db.Integer` | `INT` | `PRIMARY KEY, FK(usuarios.id) ON DELETE CASCADE` | Link 1:1 com usuario |
| `foto_url` | `db.String(255)` | `VARCHAR(255)` | `NULLABLE` | URL da foto no storage |
| `avatar` | `db.String(50)` | `VARCHAR(50)` | `NULLABLE` | Identificador do avatar estatico |
| `data_nascimento` | `db.Date` | `DATE` | `NULLABLE` | Data de nascimento |
| `posicao_principal` | `db.String(20)` | `VARCHAR(20)` | `NOT NULL` | Goleiro, Zagueiro, Lateral, Volante, Meio-campo, Meia-atacante, Atacante |
| `posicao_secundaria` | `db.String(20)` | `VARCHAR(20)` | `NULLABLE` | Segunda opcao de posicao |

**Constraint CHECK:**
- `posicao_principal IN ('Goleiro','Zagueiro','Lateral','Volante','Meio-campo','Meia-atacante','Atacante')`
- `posicao_secundaria IN ('Goleiro','Zagueiro','Lateral','Volante','Meio-campo','Meia-atacante','Atacante')` (quando NOT NULL)

**Relacionamentos SQLAlchemy:**
- `usuario` -> `usuarios` (back_populates='perfil')

---

### 3.3 Tabela: `grupos`

Requisitos atendidos: RF-005, RF-006, RF-007

| Campo | Tipo SQLAlchemy | Tipo PostgreSQL | Restricoes | Descricao |
|-------|----------------|-----------------|------------|-----------|
| `id` | `db.Integer` | `SERIAL` | `PRIMARY KEY` | Identificador unico |
| `nome` | `db.String(100)` | `VARCHAR(100)` | `NOT NULL` | Nome da pelada/grupo |
| `descricao` | `db.Text` | `TEXT` | `NULLABLE` | Regras internas, avisos |
| `logo_url` | `db.String(255)` | `VARCHAR(255)` | `NULLABLE` | URL do escudo do grupo |
| `cidade` | `db.String(100)` | `VARCHAR(100)` | `NULLABLE` | Cidade dos jogos |
| `codigo_convite` | `db.String(20)` | `VARCHAR(20)` | `UNIQUE, NOT NULL` | Codigo/link para ingresso no grupo |
| `created_at` | `db.DateTime` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Data de criacao |

**Indices:**
- `ix_grupos_codigo_convite` UNIQUE em `codigo_convite`

**Relacionamentos SQLAlchemy:**
- `membros` -> `grupo_membros` (1:N)
- `eventos` -> `eventos` (1:N)
- `avaliacoes` -> `avaliacoes_jogador` (1:N)

---

### 3.4 Tabela: `grupo_membros`

Requisitos atendidos: RF-007, RF-008, RF-009, RF-010, RF-011, RF-012, RF-013

| Campo | Tipo SQLAlchemy | Tipo PostgreSQL | Restricoes | Descricao |
|-------|----------------|-----------------|------------|-----------|
| `grupo_id` | `db.Integer` | `INT` | `PK, FK(grupos.id) ON DELETE CASCADE, NOT NULL` | Grupo vinculado |
| `usuario_id` | `db.Integer` | `INT` | `PK, FK(usuarios.id) ON DELETE CASCADE, NOT NULL` | Jogador vinculado |
| `papel` | `db.String(20)` | `VARCHAR(20)` | `DEFAULT 'membro', NOT NULL` | 'admin' ou 'membro' |
| `status` | `db.String(20)` | `VARCHAR(20)` | `DEFAULT 'pendente', NOT NULL` | 'pendente', 'aprovado', 'rejeitado' |
| `created_at` | `db.DateTime` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Data de ingresso/solicitacao |

**Primary Key:** Composite `(grupo_id, usuario_id)`

**Constraint CHECK:**
- `papel IN ('admin', 'membro')`
- `status IN ('pendente', 'aprovado', 'rejeitado')`

**Indices:**
- `ix_grupo_membros_usuario_id` em `usuario_id` (busca "meus grupos")

**Relacionamentos SQLAlchemy:**
- `grupo` -> `grupos`
- `usuario` -> `usuarios`

---

### 3.5 Tabela: `avaliacoes_jogador`

Requisitos atendidos: RF-014, RF-015

| Campo | Tipo SQLAlchemy | Tipo PostgreSQL | Restricoes | Descricao |
|-------|----------------|-----------------|------------|-----------|
| `grupo_id` | `db.Integer` | `INT` | `PK, FK(grupos.id) ON DELETE CASCADE, NOT NULL` | Contexto do grupo |
| `usuario_id` | `db.Integer` | `INT` | `PK, FK(usuarios.id) ON DELETE CASCADE, NOT NULL` | Jogador avaliado |
| `estrelas` | `db.Integer` | `INT` | `NOT NULL, CHECK(estrelas BETWEEN 1 AND 5)` | Nota tecnica (1-5) |
| `created_at` | `db.DateTime` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Data da avaliacao inicial |
| `updated_at` | `db.DateTime` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Ultima alteracao |

**Primary Key:** Composite `(grupo_id, usuario_id)`

---

### 3.6 Tabela: `historico_avaliacoes`

Requisitos atendidos: RF-016

| Campo | Tipo SQLAlchemy | Tipo PostgreSQL | Restricoes | Descricao |
|-------|----------------|-----------------|------------|-----------|
| `id` | `db.Integer` | `SERIAL` | `PRIMARY KEY` | Identificador de auditoria |
| `grupo_id` | `db.Integer` | `INT` | `FK(grupos.id) ON DELETE CASCADE, NOT NULL` | Grupo |
| `usuario_id` | `db.Integer` | `INT` | `FK(usuarios.id) ON DELETE CASCADE, NOT NULL` | Jogador avaliado |
| `admin_id` | `db.Integer` | `INT` | `FK(usuarios.id) ON DELETE SET NULL, NULLABLE` | Admin executor |
| `avaliacao_anterior` | `db.Integer` | `INT` | `NULLABLE` | Estrelas antigas (NULL = primeira avaliacao) |
| `avaliacao_nova` | `db.Integer` | `INT` | `NOT NULL` | Novas estrelas |
| `created_at` | `db.DateTime` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Data/hora da alteracao |

**Indices:**
- `ix_historico_avaliacoes_grupo_usuario` em `(grupo_id, usuario_id)` (consulta historico de um jogador)

---

### 3.7 Tabela: `eventos`

Requisitos atendidos: RF-017, RF-018, RF-019, RF-020, RF-023

| Campo | Tipo SQLAlchemy | Tipo PostgreSQL | Restricoes | Descricao |
|-------|----------------|-----------------|------------|-----------|
| `id` | `db.Integer` | `SERIAL` | `PRIMARY KEY` | Identificador do evento |
| `grupo_id` | `db.Integer` | `INT` | `FK(grupos.id) ON DELETE CASCADE, NOT NULL` | Grupo proprietario |
| `nome` | `db.String(100)` | `VARCHAR(100)` | `NOT NULL` | Ex: "Pelada de Quarta" |
| `data_evento` | `db.Date` | `DATE` | `NOT NULL` | Data do jogo |
| `horario` | `db.Time` | `TIME` | `NOT NULL` | Horario de inicio |
| `local` | `db.String(255)` | `VARCHAR(255)` | `NOT NULL` | Nome do campo/quadra |
| `observacoes` | `db.Text` | `TEXT` | `NULLABLE` | Ex: "Levar camisa branca" |
| `status_confirmacoes` | `db.String(20)` | `VARCHAR(20)` | `DEFAULT 'aberto', NOT NULL` | 'aberto' ou 'encerrado' |
| `cancelado_em` | `db.DateTime` | `TIMESTAMPTZ` | `NULLABLE` | Data/hora do cancelamento (NULL = ativo) |
| `motivo_cancelamento` | `db.String(255)` | `VARCHAR(255)` | `NULLABLE` | Motivo informado pelo admin |
| `is_active` | `db.Boolean` | `BOOLEAN` | `DEFAULT TRUE` | Soft delete |
| `created_at` | `db.DateTime` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Data de criacao |

**Constraint CHECK:**
- `status_confirmacoes IN ('aberto', 'encerrado')`

**Indices:**
- `ix_eventos_grupo_id` em `grupo_id`
- `ix_eventos_data_evento` em `data_evento` (listagem cronologica)

**Relacionamentos SQLAlchemy:**
- `grupo` -> `grupos`
- `participantes` -> `evento_participantes` (1:N)
- `sorteio` -> `sorteios` (1:1, uselist=False)

---

### 3.8 Tabela: `evento_participantes`

Requisitos atendidos: RF-021, RF-022, RF-024, RF-028

| Campo | Tipo SQLAlchemy | Tipo PostgreSQL | Restricoes | Descricao |
|-------|----------------|-----------------|------------|-----------|
| `evento_id` | `db.Integer` | `INT` | `PK, FK(eventos.id) ON DELETE CASCADE, NOT NULL` | Evento |
| `usuario_id` | `db.Integer` | `INT` | `PK, FK(usuarios.id) ON DELETE CASCADE, NOT NULL` | Jogador |
| `resposta` | `db.String(20)` | `VARCHAR(20)` | `NOT NULL` | 'confirmado', 'nao_vou', 'talvez' |
| `created_at` | `db.DateTime` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Quando respondeu pela primeira vez |
| `updated_at` | `db.DateTime` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Ultima alteracao de status |

**Primary Key:** Composite `(evento_id, usuario_id)`

**Constraint CHECK:**
- `resposta IN ('confirmado', 'nao_vou', 'talvez')`

**Indices:**
- `ix_evento_participantes_usuario_id` em `usuario_id`

---

### 3.9 Tabela: `sorteios`

Requisitos atendidos: RF-025, RF-026, RF-027, RF-032, RF-033, RF-041

| Campo | Tipo SQLAlchemy | Tipo PostgreSQL | Restricoes | Descricao |
|-------|----------------|-----------------|------------|-----------|
| `id` | `db.Integer` | `SERIAL` | `PRIMARY KEY` | Identificador do sorteio |
| `evento_id` | `db.Integer` | `INT` | `FK(eventos.id) ON DELETE CASCADE, UNIQUE, NOT NULL` | Evento vinculado (1:1) |
| `modalidade` | `db.String(20)` | `VARCHAR(20)` | `NOT NULL` | 'aleatorio' ou 'balanceado' |
| `qtd_times` | `db.Integer` | `INT` | `NOT NULL, CHECK(qtd_times >= 2)` | Quantidade de times |
| `max_jogadores_time` | `db.Integer` | `INT` | `NULLABLE` | Limite por time (NULL = sem limite) |
| `qtd_goleiros_time` | `db.Integer` | `INT` | `NULLABLE` | Goleiros por time (NULL = sem restricao) |
| `status` | `db.String(20)` | `VARCHAR(20)` | `DEFAULT 'pendente', NOT NULL` | 'pendente', 'realizado', 'confirmado' |
| `created_at` | `db.DateTime` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Data de criacao |
| `confirmado_em` | `db.DateTime` | `TIMESTAMPTZ` | `NULLABLE` | Data da confirmacao final |

**Constraint CHECK:**
- `modalidade IN ('aleatorio', 'balanceado')`
- `status IN ('pendente', 'realizado', 'confirmado')`

**Constraint UNIQUE:**
- `evento_id` (garante 1 sorteio por evento)

**Indices:**
- `ix_sorteios_evento_id` UNIQUE em `evento_id`

**Relacionamentos SQLAlchemy:**
- `evento` -> `eventos` (back_populates='sorteio')
- `times` -> `times` (1:N, cascade='all, delete-orphan')

---

### 3.10 Tabela: `times`

Requisitos atendidos: RF-026, RF-038, RF-039

| Campo | Tipo SQLAlchemy | Tipo PostgreSQL | Restricoes | Descricao |
|-------|----------------|-----------------|------------|-----------|
| `id` | `db.Integer` | `SERIAL` | `PRIMARY KEY` | Identificador do time |
| `sorteio_id` | `db.Integer` | `INT` | `FK(sorteios.id) ON DELETE CASCADE, NOT NULL` | Sorteio pai |
| `nome` | `db.String(50)` | `VARCHAR(50)` | `NOT NULL` | Nome do time (ex: "Time A") |
| `ordem` | `db.Integer` | `INT` | `NOT NULL` | Ordem de exibicao (1, 2, 3...) |

**Indices:**
- `ix_times_sorteio_id` em `sorteio_id`

**Constraint UNIQUE:**
- `(sorteio_id, ordem)` — sem duplicata de ordem no mesmo sorteio
- `(sorteio_id, nome)` — sem duplicata de nome no mesmo sorteio

**Relacionamentos SQLAlchemy:**
- `sorteio` -> `sorteios`
- `jogadores` -> `time_jogadores` (1:N, cascade='all, delete-orphan')

---

### 3.11 Tabela: `time_jogadores`

Requisitos atendidos: RF-029, RF-031, RF-038, RF-039

| Campo | Tipo SQLAlchemy | Tipo PostgreSQL | Restricoes | Descricao |
|-------|----------------|-----------------|------------|-----------|
| `time_id` | `db.Integer` | `INT` | `PK, FK(times.id) ON DELETE CASCADE, NOT NULL` | Time |
| `usuario_id` | `db.Integer` | `INT` | `PK, FK(usuarios.id) ON DELETE CASCADE, NOT NULL` | Jogador |
| `posicao` | `db.String(20)` | `VARCHAR(20)` | `NOT NULL` | Posicao no momento do sorteio (snapshot) |
| `estrelas` | `db.Integer` | `INT` | `NOT NULL, DEFAULT 3` | Estrelas no momento do sorteio (snapshot) |
| `eh_goleiro` | `db.Boolean` | `BOOLEAN` | `DEFAULT FALSE` | Flag para facilitar consulta de goleiros |

**Primary Key:** Composite `(time_id, usuario_id)`

> **Nota:** `posicao` e `estrelas` sao snapshots congelados no momento do sorteio conforme especificado no `geral.md` seção 3.9. Alteracoes posteriores na avaliacao ou perfil do jogador NAO retroagem.

---

### 3.12 Tabela: `notificacoes`

Requisitos atendidos: RF-043, RF-044, RF-045, RF-046

| Campo | Tipo SQLAlchemy | Tipo PostgreSQL | Restricoes | Descricao |
|-------|----------------|-----------------|------------|-----------|
| `id` | `db.Integer` | `SERIAL` | `PRIMARY KEY` | Identificador |
| `usuario_id` | `db.Integer` | `INT` | `FK(usuarios.id) ON DELETE CASCADE, NOT NULL` | Destinatario |
| `tipo` | `db.String(30)` | `VARCHAR(30)` | `NOT NULL` | Tipo da notificacao |
| `titulo` | `db.String(150)` | `VARCHAR(150)` | `NOT NULL` | Titulo curto |
| `mensagem` | `db.Text` | `TEXT` | `NULLABLE` | Corpo da notificacao |
| `referencia_tipo` | `db.String(30)` | `VARCHAR(30)` | `NULLABLE` | Tipo da entidade referenciada ('evento', 'grupo', 'sorteio') |
| `referencia_id` | `db.Integer` | `INT` | `NULLABLE` | ID da entidade referenciada |
| `lida` | `db.Boolean` | `BOOLEAN` | `DEFAULT FALSE` | Se foi lida |
| `created_at` | `db.DateTime` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Data de criacao |

**Constraint CHECK:**
- `tipo IN ('novo_evento', 'aprovacao_grupo', 'sorteio_iniciado', 'sorteio_finalizado', 'rejeicao_grupo', 'promovido_admin', 'removido_grupo')`

**Indices:**
- `ix_notificacoes_usuario_id` em `usuario_id`
- `ix_notificacoes_usuario_lida` em `(usuario_id, lida)` (listar nao lidas)
- `ix_notificacoes_created_at` em `created_at` (ordenacao cronologica)

---

### 3.13 Tabela: `password_reset_tokens`

Requisitos atendidos: RF-003

| Campo | Tipo SQLAlchemy | Tipo PostgreSQL | Restricoes | Descricao |
|-------|----------------|-----------------|------------|-----------|
| `id` | `db.Integer` | `SERIAL` | `PRIMARY KEY` | Identificador |
| `usuario_id` | `db.Integer` | `INT` | `FK(usuarios.id) ON DELETE CASCADE, NOT NULL` | Usuario solicitante |
| `token` | `db.String(255)` | `VARCHAR(255)` | `UNIQUE, NOT NULL` | Token seguro (secrets.token_urlsafe) |
| `expires_at` | `db.DateTime` | `TIMESTAMPTZ` | `NOT NULL` | Expiracao (NOW() + 1 hora) |
| `used` | `db.Boolean` | `BOOLEAN` | `DEFAULT FALSE` | Se ja foi utilizado |
| `created_at` | `db.DateTime` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Data de criacao |

**Indices:**
- `ix_password_reset_tokens_token` UNIQUE em `token`
- `ix_password_reset_tokens_usuario_id` em `usuario_id`

---

## 4. DIAGRAMA DE RELACIONAMENTOS (DER)

```
usuarios (1) -------- (1) perfis_jogador
    |
    |--- (N) grupo_membros (N) --- (1) grupos
    |                                    |
    |--- (N) evento_participantes (N)    |--- (N) eventos
    |                                    |          |
    |--- (N) avaliacoes_jogador (N) -----+          |--- (1) sorteios
    |                                               |          |
    |--- (N) historico_avaliacoes                    |          |--- (N) times
    |                                               |                    |
    |--- (N) notificacoes                           |                    |--- (N) time_jogadores
    |
    |--- (N) password_reset_tokens
```

**Resumo dos relacionamentos:**

| Relacao | Tipo | Cascade |
|---------|------|---------|
| `usuarios` -> `perfis_jogador` | 1:1 | CASCADE |
| `usuarios` <-> `grupos` (via `grupo_membros`) | N:M | CASCADE |
| `usuarios` <-> `eventos` (via `evento_participantes`) | N:M | CASCADE |
| `usuarios` <-> `grupos` (via `avaliacoes_jogador`) | N:M | CASCADE |
| `grupos` -> `eventos` | 1:N | CASCADE |
| `eventos` -> `sorteios` | 1:1 | CASCADE |
| `sorteios` -> `times` | 1:N | CASCADE (delete-orphan) |
| `times` -> `time_jogadores` | 1:N | CASCADE (delete-orphan) |
| `usuarios` -> `notificacoes` | 1:N | CASCADE |
| `usuarios` -> `password_reset_tokens` | 1:N | CASCADE |
| `usuarios` -> `historico_avaliacoes` | 1:N | CASCADE |

---

## 5. INSTRUCOES DE IMPLEMENTACAO (Flask-Migrate)

### 5.1 Estrutura de Arquivos dos Models

```
app/
├── models/
│   ├── __init__.py              # Importa todos os models para o Alembic detectar
│   ├── usuario.py               # Usuario + PerfilJogador
│   ├── grupo.py                 # Grupo + GrupoMembro + AvaliacaoJogador
│   ├── evento.py                # Evento + EventoParticipante
│   ├── sorteio.py               # Sorteio + Time + TimeJogador
│   ├── historico_avaliacao.py   # HistoricoAvaliacao
│   ├── notificacao.py           # Notificacao
│   └── password_reset.py        # PasswordResetToken
```

### 5.2 Dependencias Python

```
Flask==3.1.*
Flask-SQLAlchemy==3.1.*
Flask-Migrate==4.1.*
psycopg2-binary==2.9.*
bcrypt==4.2.*
```

### 5.3 Configuracao do Database (app/database.py)

```python
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

db = SQLAlchemy()
migrate = Migrate()
```

### 5.4 Application Factory (app/__init__.py)

```python
from flask import Flask
from app.database import db, migrate

def create_app():
    app = Flask(__name__)
    app.config.from_object('app.config.Config')

    db.init_app(app)
    migrate.init_app(app, db)

    # Importar models para o Alembic detectar
    from app import models  # noqa: F401

    return app
```

### 5.5 Configuracao do Banco (app/config.py)

```python
import os

class Config:
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        'DATABASE_URL',
        'postgresql://usuario:senha@localhost:5432/futebol_app'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_size': 10,
        'pool_recycle': 300,
        'max_overflow': 5,
    }
```

### 5.6 Comandos de Migracao

```bash
# Inicializar o diretorio de migracoes (apenas primeira vez)
flask db init

# Gerar migracao a partir dos models
flask db migrate -m "criar tabelas iniciais"

# Aplicar migracao no banco
flask db upgrade

# Reverter ultima migracao
flask db downgrade
```

### 5.7 Ordem de Criacao das Tabelas (respeitando FKs)

1. `usuarios`
2. `perfis_jogador`
3. `grupos`
4. `grupo_membros`
5. `avaliacoes_jogador`
6. `historico_avaliacoes`
7. `eventos`
8. `evento_participantes`
9. `sorteios`
10. `times`
11. `time_jogadores`
12. `notificacoes`
13. `password_reset_tokens`

> **Nota:** O Alembic/Flask-Migrate resolve a ordem automaticamente com base nas FKs declaradas nos models. A lista acima serve como referencia logica.

---

## 6. REGRAS DE NEGOCIO REFLETIDAS NO BANCO

| Regra | Implementacao no Banco |
|-------|----------------------|
| RF-001: Username e email unicos | `UNIQUE` constraint em `usuarios.email` e `usuarios.username` |
| RF-005: Criador vira admin | Inserir em `grupo_membros` com `papel='admin'` e `status='aprovado'` na service layer |
| RF-011: Grupo sem admin | CHECK na service layer (nao no banco) antes de remover ultimo admin |
| RF-014: Estrelas 1-5 | `CHECK(estrelas BETWEEN 1 AND 5)` em `avaliacoes_jogador` |
| RF-023: Apenas confirmados no sorteio | Filtro na service layer: `evento_participantes.resposta = 'confirmado'` |
| RF-025: 1 sorteio por evento | `UNIQUE` em `sorteios.evento_id` |
| RF-029: Snapshot de estrelas | `time_jogadores.estrelas` congela o valor no momento do sorteio |
| RF-033: Confirmacao final | `sorteios.status` transiciona de 'realizado' para 'confirmado', `confirmado_em` preenchido |

---

## 7. INDICES DE PERFORMANCE

| Indice | Tabela | Colunas | Justificativa |
|--------|--------|---------|---------------|
| `ix_usuarios_email` | `usuarios` | `email` | Login por email, busca unica |
| `ix_usuarios_username` | `usuarios` | `username` | Login por username, busca unica |
| `ix_grupo_membros_usuario_id` | `grupo_membros` | `usuario_id` | "Meus grupos" |
| `ix_eventos_grupo_id` | `eventos` | `grupo_id` | Listar eventos do grupo |
| `ix_eventos_data_evento` | `eventos` | `data_evento` | Ordenacao cronologica |
| `ix_evento_participantes_usuario_id` | `evento_participantes` | `usuario_id` | "Meus eventos" |
| `ix_sorteios_evento_id` | `sorteios` | `evento_id` | Buscar sorteio do evento |
| `ix_times_sorteio_id` | `times` | `sorteio_id` | Listar times do sorteio |
| `ix_historico_avaliacoes_grupo_usuario` | `historico_avaliacoes` | `(grupo_id, usuario_id)` | Historico de avaliacoes |
| `ix_notificacoes_usuario_lida` | `notificacoes` | `(usuario_id, lida)` | Notificacoes nao lidas |
| `ix_notificacoes_created_at` | `notificacoes` | `created_at` | Ordenacao cronologica |
| `ix_grupos_codigo_convite` | `grupos` | `codigo_convite` | Busca por convite |
| `ix_password_reset_tokens_token` | `password_reset_tokens` | `token` | Validacao do token |

---

## 8. PROXIMOS PASSOS

1. **Gerar os Models SQLAlchemy** — Criar cada arquivo em `app/models/` com as classes Python correspondentes a este spec
2. **Gerar a Migration Inicial** — Rodar `flask db migrate -m "criar tabelas iniciais"` e revisar o script gerado
3. **Aplicar no PostgreSQL** — Rodar `flask db upgrade` no ambiente de desenvolvimento
4. **Seed de Dados** — Criar script de seed com dados de teste (posicoes, usuario admin, grupo exemplo)
5. **Validar Relacionamentos** — Testar inserções e queries nos relacionamentos criticos (sorteio completo)
