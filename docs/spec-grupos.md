# SPEC - MODULO DE GRUPOS

**Projeto:** Sistema de Gerenciamento de Grupos de Futebol Amador  
**Stack:** Flask + Flask-SQLAlchemy + JWT  
**Requisitos:** RF-005 a RF-013  
**Baseado em:** `geral.md`, `requisitos.md`, `spec-banco-de-dados.md`  
**Data:** 2026-06-29

---

## 1. VISAO GERAL

Modulo responsavel por criar, editar e gerenciar grupos de futebol, membros, solicitacoes de entrada, papeis (admin/membro) e controle de acesso. Depende do modulo Auth (usuario autenticado).

---

## 2. ESTRUTURA DE ARQUIVOS

```
app/
├── blueprints/
│   └── grupos/
│       ├── __init__.py       # Blueprint com prefix /api/grupos
│       └── routes.py         # Endpoints REST
│
├── services/
│   └── grupo_service.py      # Logica de negocio
│
├── utils/
│   └── decorators.py         # @membro_required, @admin_required (adicionar)
```

---

## 3. ENDPOINTS

### 3.1 Criar Grupo

**`POST /api/grupos`** — RF-005

**Header:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "nome": "Pelada de Quarta",
  "descricao": "Toda quarta, 20h, campo do Sesi",
  "logo_url": null,
  "cidade": "Vitoria"
}
```

**Validacoes:**
| Campo | Regra | Erro |
|-------|-------|------|
| `nome` | Obrigatorio, 3-100 caracteres | `"Nome deve ter entre 3 e 100 caracteres"` |
| `descricao` | Opcional | - |
| `cidade` | Opcional, max 100 caracteres | `"Cidade deve ter no maximo 100 caracteres"` |

**Fluxo:**
1. Validar campos
2. Gerar `codigo_convite` unico (8 chars alfanumericos)
3. Criar registro em `grupos`
4. Inserir criador em `grupo_membros` com `papel='admin'`, `status='aprovado'`
5. Retornar grupo criado

**Response 201:**
```json
{
  "message": "Grupo criado com sucesso",
  "grupo": {
    "id": 1,
    "nome": "Pelada de Quarta",
    "descricao": "Toda quarta, 20h, campo do Sesi",
    "logo_url": null,
    "cidade": "Vitoria",
    "codigo_convite": "X7kM9pQw",
    "created_at": "2026-06-29T10:00:00Z",
    "papel": "admin",
    "total_membros": 1
  }
}
```

---

### 3.2 Listar Meus Grupos

**`GET /api/grupos`**

**Header:** `Authorization: Bearer <access_token>`

**Response 200:**
```json
{
  "grupos": [
    {
      "id": 1,
      "nome": "Pelada de Quarta",
      "logo_url": null,
      "cidade": "Vitoria",
      "papel": "admin",
      "total_membros": 12
    }
  ]
}
```

> Retorna apenas grupos onde o usuario tem `status='aprovado'`.

---

### 3.3 Detalhes do Grupo

**`GET /api/grupos/:id`**

**Header:** `Authorization: Bearer <access_token>`

**Restricao:** Apenas membros aprovados do grupo.

**Response 200:**
```json
{
  "grupo": {
    "id": 1,
    "nome": "Pelada de Quarta",
    "descricao": "Toda quarta, 20h, campo do Sesi",
    "logo_url": null,
    "cidade": "Vitoria",
    "codigo_convite": "X7kM9pQw",
    "created_at": "2026-06-29T10:00:00Z",
    "papel": "admin",
    "total_membros": 12
  }
}
```

> `codigo_convite` so e retornado para admins.

---

### 3.4 Editar Grupo

**`PUT /api/grupos/:id`** — RF-006

**Header:** `Authorization: Bearer <access_token>`

**Restricao:** Apenas admins do grupo.

**Request Body (todos opcionais):**
```json
{
  "nome": "Pelada de Quarta - Novo Nome",
  "descricao": "Regras atualizadas",
  "logo_url": "https://storage.../logo.jpg",
  "cidade": "Vila Velha",
  "regenerar_convite": true
}
```

> `regenerar_convite: true` gera um novo `codigo_convite`, invalidando o anterior.

**Response 200:**
```json
{
  "message": "Grupo atualizado com sucesso",
  "grupo": { ... }
}
```

---

### 3.5 Solicitar Entrada no Grupo

**`POST /api/grupos/entrar`** — RF-007

**Header:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "codigo_convite": "X7kM9pQw"
}
```

**Fluxo:**
1. Buscar grupo pelo `codigo_convite`
2. Verificar se usuario ja e membro (aprovado ou pendente)
3. Criar registro em `grupo_membros` com `papel='membro'`, `status='pendente'`
4. Criar notificacao para todos os admins do grupo

**Erros:**
| Status | Condicao | Resposta |
|--------|----------|----------|
| 400 | Codigo ausente | `"Informe o codigo de convite"` |
| 404 | Codigo invalido | `"Codigo de convite invalido"` |
| 409 | Ja e membro ou pendente | `"Voce ja faz parte deste grupo"` / `"Solicitacao ja enviada"` |

**Response 201:**
```json
{
  "message": "Solicitacao enviada com sucesso",
  "grupo": {
    "id": 1,
    "nome": "Pelada de Quarta"
  }
}
```

---

### 3.6 Listar Membros do Grupo

**`GET /api/grupos/:id/membros`**

**Header:** `Authorization: Bearer <access_token>`

**Restricao:** Apenas membros aprovados.

**Response 200:**
```json
{
  "membros": [
    {
      "usuario_id": 1,
      "nome": "Wesley Xavier",
      "apelido": "Xavs",
      "foto_url": null,
      "posicao_principal": "Meio-campo",
      "papel": "admin",
      "estrelas": 4
    }
  ]
}
```

> Inclui `estrelas` da tabela `avaliacoes_jogador` (NULL se nao avaliado).

---

### 3.7 Listar Solicitacoes Pendentes

**`GET /api/grupos/:id/pendentes`**

**Header:** `Authorization: Bearer <access_token>`

**Restricao:** Apenas admins.

**Response 200:**
```json
{
  "pendentes": [
    {
      "usuario_id": 5,
      "nome": "Carlos Silva",
      "apelido": "Carlao",
      "posicao_principal": "Zagueiro",
      "created_at": "2026-06-29T11:00:00Z"
    }
  ]
}
```

---

### 3.8 Aprovar Solicitacao

**`PUT /api/grupos/:id/membros/:uid/aprovar`** — RF-008

**Header:** `Authorization: Bearer <access_token>`

**Restricao:** Apenas admins.

**Fluxo:**
1. Verificar se `uid` tem `status='pendente'` no grupo
2. Atualizar `status` para `'aprovado'`
3. Criar notificacao para o usuario aprovado (tipo `aprovacao_grupo`)

**Response 200:**
```json
{
  "message": "Membro aprovado com sucesso"
}
```

---

### 3.9 Rejeitar Solicitacao

**`PUT /api/grupos/:id/membros/:uid/rejeitar`** — RF-008

**Header:** `Authorization: Bearer <access_token>`

**Restricao:** Apenas admins.

**Fluxo:**
1. Verificar se `uid` tem `status='pendente'`
2. Atualizar `status` para `'rejeitado'`
3. Criar notificacao (tipo `rejeicao_grupo`)

**Response 200:**
```json
{
  "message": "Solicitacao rejeitada"
}
```

---

### 3.10 Promover a Administrador

**`PUT /api/grupos/:id/membros/:uid/promover`** — RF-010

**Header:** `Authorization: Bearer <access_token>`

**Restricao:** Apenas admins.

**Validacoes:**
- `uid` deve ser membro aprovado
- `uid` nao pode ja ser admin

**Fluxo:**
1. Atualizar `papel` para `'admin'`
2. Criar notificacao (tipo `promovido_admin`)

**Response 200:**
```json
{
  "message": "Membro promovido a administrador"
}
```

---

### 3.11 Rebaixar Administrador

**`PUT /api/grupos/:id/membros/:uid/rebaixar`** — RF-011

**Header:** `Authorization: Bearer <access_token>`

**Restricao:** Apenas admins.

**Validacoes:**
- `uid` deve ser admin
- `uid` nao pode ser o ultimo admin do grupo

**Fluxo:**
1. Contar admins do grupo
2. Se `uid` for o ultimo admin → erro 400
3. Atualizar `papel` para `'membro'`

**Response 200:**
```json
{
  "message": "Administrador rebaixado para membro"
}
```

**Erro:**
```json
{
  "error": "O grupo deve ter pelo menos um administrador"
}
```

---

### 3.12 Remover Membro

**`DELETE /api/grupos/:id/membros/:uid`** — RF-012

**Header:** `Authorization: Bearer <access_token>`

**Restricao:** Apenas admins.

**Validacoes:**
- Nao pode remover a si mesmo (usar `sair` para isso)
- Se `uid` for admin, verificar se nao e o ultimo

**Fluxo:**
1. Deletar registro de `grupo_membros`
2. Criar notificacao (tipo `removido_grupo`)

**Response 200:**
```json
{
  "message": "Membro removido do grupo"
}
```

---

### 3.13 Sair do Grupo

**`DELETE /api/grupos/:id/sair`** — RF-013

**Header:** `Authorization: Bearer <access_token>`

**Restricao:** Membro aprovado.

**Validacoes:**
- Se for admin e o ultimo admin → erro 400

**Response 200:**
```json
{
  "message": "Voce saiu do grupo"
}
```

**Erro:**
```json
{
  "error": "Voce e o unico administrador. Promova outro membro antes de sair"
}
```

---

## 4. DECORATORS ADICIONAIS

### 4.1 @membro_required(grupo_id_param)

Verifica se o usuario logado e membro aprovado do grupo. Injeta `g.membro` no contexto.

### 4.2 @admin_required(grupo_id_param)

Verifica se o usuario logado e admin do grupo. Injeta `g.membro` no contexto.

Ambos dependem do `@token_required` ja existente.

---

## 5. RESUMO DOS ENDPOINTS

| Metodo | Rota | Permissao | Descricao | RF |
|--------|------|-----------|-----------|-----|
| POST | `/api/grupos` | Autenticado | Criar grupo | RF-005 |
| GET | `/api/grupos` | Autenticado | Listar meus grupos | - |
| GET | `/api/grupos/:id` | Membro | Detalhes do grupo | - |
| PUT | `/api/grupos/:id` | Admin | Editar grupo | RF-006 |
| POST | `/api/grupos/entrar` | Autenticado | Solicitar entrada | RF-007 |
| GET | `/api/grupos/:id/membros` | Membro | Listar membros | RF-009 |
| GET | `/api/grupos/:id/pendentes` | Admin | Listar pendentes | RF-008 |
| PUT | `/api/grupos/:id/membros/:uid/aprovar` | Admin | Aprovar | RF-008 |
| PUT | `/api/grupos/:id/membros/:uid/rejeitar` | Admin | Rejeitar | RF-008 |
| PUT | `/api/grupos/:id/membros/:uid/promover` | Admin | Promover admin | RF-010 |
| PUT | `/api/grupos/:id/membros/:uid/rebaixar` | Admin | Rebaixar admin | RF-011 |
| DELETE | `/api/grupos/:id/membros/:uid` | Admin | Remover membro | RF-012 |
| DELETE | `/api/grupos/:id/sair` | Membro | Sair do grupo | RF-013 |

---

## 6. ORDEM DE IMPLEMENTACAO

1. `app/utils/decorators.py` — Adicionar `@membro_required` e `@admin_required`
2. `app/services/grupo_service.py` — Logica de negocio completa
3. `app/blueprints/grupos/__init__.py` — Blueprint registration
4. `app/blueprints/grupos/routes.py` — 13 endpoints
5. Registrar blueprint no `create_app()`
