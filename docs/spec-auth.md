# SPEC - MODULO DE AUTENTICACAO (Auth)

**Projeto:** Sistema de Gerenciamento de Grupos de Futebol Amador  
**Stack:** Flask + Flask-SQLAlchemy + JWT (PyJWT) + Bcrypt  
**Requisitos:** RF-001 (Cadastro), RF-002 (Login), RF-003 (Recuperacao de Senha), RF-004 (Perfil)  
**Baseado em:** `geral.md`, `requisitos.md`, `spec-banco-de-dados.md`  
**Data:** 2026-06-29

---

## 1. VISAO GERAL

Modulo responsavel por registro, autenticacao, gestao de sessao via JWT e recuperacao de senha. E o primeiro modulo a ser implementado pois todos os demais dependem de usuario autenticado.

### 1.1 Estrategia de Autenticacao

- **Tipo:** Token-based (JWT - JSON Web Token)
- **Motivo:** App mobile (Flutter) nao usa cookies/sessoes server-side. JWT e stateless, leve para VPS pequena, e compativel com REST API.
- **Biblioteca:** `PyJWT` (leve, sem dependencias extras)
- **Hash de Senha:** `bcrypt` via biblioteca `bcrypt`

### 1.2 Arquitetura de Tokens

| Token | Finalidade | Expiracao | Armazenamento no App |
|-------|-----------|-----------|---------------------|
| **Access Token** | Autorizacao de requisicoes | 15 minutos | Memoria (Riverpod state) |
| **Refresh Token** | Renovar access token sem re-login | 30 dias | SharedPreferences / flutter_secure_storage |

**Fluxo:**
1. Usuario faz login -> recebe `access_token` + `refresh_token`
2. Todas as requisicoes enviam o `access_token` no header `Authorization: Bearer <token>`
3. Quando o `access_token` expira, o app chama `/auth/refresh` com o `refresh_token`
4. Se o `refresh_token` tambem expirou -> usuario precisa fazer login novamente

---

## 2. ESTRUTURA DE ARQUIVOS

```
app/
├── blueprints/
│   └── auth/
│       ├── __init__.py       # Registra o Blueprint
│       └── routes.py         # Endpoints REST
│
├── services/
│   └── auth_service.py       # Logica de negocio (hash, JWT, validacao)
│
├── utils/
│   ├── jwt_utils.py          # Geracao e validacao de tokens JWT
│   └── decorators.py         # @token_required, @admin_required
│
├── models/
│   ├── usuario.py            # Model Usuario (ja definido na spec-banco)
│   └── password_reset.py     # Model PasswordResetToken
```

---

## 3. ENDPOINTS DA API

### 3.1 Registro de Usuario

**`POST /api/auth/registro`** — RF-001

**Request Body:**
```json
{
  "nome": "Wesley Xavier",
  "apelido": "Xavs",
  "email": "wesley@email.com",
  "username": "xavs10",
  "senha": "MinhaSenh@123",
  "posicao_principal": "Meio-campo",
  "posicao_secundaria": "Atacante"
}
```

**Validacoes:**
| Campo | Regra | Erro |
|-------|-------|------|
| `nome` | Obrigatorio, 3-100 caracteres | `"Nome deve ter entre 3 e 100 caracteres"` |
| `apelido` | Opcional, max 50 caracteres | `"Apelido deve ter no maximo 50 caracteres"` |
| `email` | Obrigatorio, formato valido, unico no banco | `"E-mail invalido"` / `"E-mail ja cadastrado"` |
| `username` | Obrigatorio, 3-50 caracteres, alfanumerico + underscore, unico | `"Username deve ter entre 3 e 50 caracteres"` / `"Username ja esta em uso"` |
| `senha` | Obrigatorio, minimo 8 caracteres, 1 maiuscula, 1 numero, 1 especial | `"Senha nao atende os criterios de seguranca"` |
| `posicao_principal` | Obrigatorio, valor valido da lista de posicoes | `"Posicao invalida"` |
| `posicao_secundaria` | Opcional, valor valido se informado | `"Posicao invalida"` |

**Posicoes validas:** `Goleiro`, `Zagueiro`, `Lateral`, `Volante`, `Meio-campo`, `Meia-atacante`, `Atacante`

**Fluxo:**
1. Validar todos os campos de entrada
2. Verificar unicidade de `email` e `username` no banco
3. Gerar hash da senha com `bcrypt`
4. Criar registro em `usuarios`
5. Criar registro em `perfis_jogador` com `posicao_principal` e `posicao_secundaria`
6. Gerar `access_token` e `refresh_token`
7. Retornar dados do usuario + tokens

**Response 201:**
```json
{
  "message": "Usuario cadastrado com sucesso",
  "usuario": {
    "id": 1,
    "nome": "Wesley Xavier",
    "apelido": "Xavs",
    "email": "wesley@email.com",
    "username": "xavs10"
  },
  "access_token": "eyJ...",
  "refresh_token": "eyJ..."
}
```

**Erros:**
| Status | Condicao | Resposta |
|--------|----------|----------|
| 400 | Campos invalidos | `{"error": "Mensagem especifica do campo"}` |
| 409 | Email ou username duplicado | `{"error": "E-mail ja cadastrado"}` |

---

### 3.2 Login

**`POST /api/auth/login`** — RF-002

**Request Body:**
```json
{
  "login": "xavs10",
  "senha": "MinhaSenh@123"
}
```

> O campo `login` aceita tanto `username` quanto `email`. O backend detecta automaticamente pelo formato (contem `@` = email).

**Validacoes:**
| Campo | Regra | Erro |
|-------|-------|------|
| `login` | Obrigatorio | `"Informe seu usuario ou e-mail"` |
| `senha` | Obrigatorio | `"Informe sua senha"` |

**Fluxo:**
1. Receber `login` e `senha`
2. Detectar se `login` e email (contem `@`) ou username
3. Buscar usuario no banco por email ou username
4. Verificar se `is_active = True` (usuario nao desativado)
5. Comparar `senha` com `senha_hash` usando `bcrypt.checkpw()`
6. Gerar `access_token` e `refresh_token`
7. Retornar dados do usuario + tokens

**Response 200:**
```json
{
  "message": "Login realizado com sucesso",
  "usuario": {
    "id": 1,
    "nome": "Wesley Xavier",
    "apelido": "Xavs",
    "email": "wesley@email.com",
    "username": "xavs10",
    "perfil": {
      "foto_url": null,
      "avatar": null,
      "posicao_principal": "Meio-campo",
      "posicao_secundaria": "Atacante"
    }
  },
  "access_token": "eyJ...",
  "refresh_token": "eyJ..."
}
```

**Erros:**
| Status | Condicao | Resposta |
|--------|----------|----------|
| 400 | Campos ausentes | `{"error": "Informe seu usuario ou e-mail"}` |
| 401 | Credenciais invalidas | `{"error": "Usuario ou senha incorretos"}` |
| 403 | Conta desativada | `{"error": "Conta desativada. Entre em contato com o suporte"}` |

> **Seguranca:** A mensagem de erro NAO diferencia se o usuario nao existe ou se a senha esta errada. Sempre retorna `"Usuario ou senha incorretos"` para evitar enumeracao de contas.

---

### 3.3 Refresh Token

**`POST /api/auth/refresh`**

**Request Body:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Fluxo:**
1. Decodificar o `refresh_token`
2. Verificar se nao expirou
3. Verificar se o `type` do token e `"refresh"` (nao aceitar access token aqui)
4. Buscar usuario no banco e verificar `is_active = True`
5. Gerar novo `access_token`
6. Retornar novo token

**Response 200:**
```json
{
  "access_token": "eyJ..."
}
```

**Erros:**
| Status | Condicao | Resposta |
|--------|----------|----------|
| 401 | Token expirado ou invalido | `{"error": "Token invalido ou expirado"}` |
| 403 | Conta desativada | `{"error": "Conta desativada"}` |

---

### 3.4 Solicitar Recuperacao de Senha

**`POST /api/auth/esqueci-senha`** — RF-003

**Request Body:**
```json
{
  "email": "wesley@email.com"
}
```

**Fluxo:**
1. Receber o email
2. Buscar usuario pelo email
3. Se encontrado E ativo:
   a. Invalidar tokens de reset anteriores nao utilizados (marcar `used = True`)
   b. Gerar token seguro com `secrets.token_urlsafe(32)`
   c. Criar registro em `password_reset_tokens` com expiracao de 1 hora
   d. Enviar email com link/codigo contendo o token
4. Retornar SEMPRE a mesma mensagem de sucesso (independente se o email existe ou nao)

**Response 200 (SEMPRE):**
```json
{
  "message": "Se o e-mail estiver cadastrado, voce recebera as instrucoes de recuperacao"
}
```

> **Seguranca:** Nunca revelar se o email existe no banco. Resposta identica em todos os casos.

---

### 3.5 Redefinir Senha

**`POST /api/auth/redefinir-senha`** — RF-003

**Request Body:**
```json
{
  "token": "abc123tokenSeguro",
  "nova_senha": "NovaSenha@456"
}
```

**Validacoes:**
| Campo | Regra | Erro |
|-------|-------|------|
| `token` | Obrigatorio, valido, nao expirado, nao utilizado | `"Token invalido ou expirado"` |
| `nova_senha` | Mesmas regras de senha do cadastro | `"Senha nao atende os criterios de seguranca"` |

**Fluxo:**
1. Buscar token em `password_reset_tokens`
2. Verificar: existe, `used = False`, `expires_at > NOW()`
3. Validar nova senha (criterios de seguranca)
4. Gerar novo hash com bcrypt
5. Atualizar `senha_hash` em `usuarios`
6. Marcar token como `used = True`
7. Retornar confirmacao

**Response 200:**
```json
{
  "message": "Senha redefinida com sucesso"
}
```

**Erros:**
| Status | Condicao | Resposta |
|--------|----------|----------|
| 400 | Senha fraca | `{"error": "Senha nao atende os criterios de seguranca"}` |
| 401 | Token invalido/expirado/usado | `{"error": "Token invalido ou expirado"}` |

---

### 3.6 Obter Perfil do Usuario Logado

**`GET /api/auth/me`** — RF-004 (leitura)

**Header:** `Authorization: Bearer <access_token>`

**Fluxo:**
1. Decorator `@token_required` valida o token
2. Buscar usuario + perfil_jogador pelo `user_id` do token
3. Retornar dados completos

**Response 200:**
```json
{
  "usuario": {
    "id": 1,
    "nome": "Wesley Xavier",
    "apelido": "Xavs",
    "email": "wesley@email.com",
    "username": "xavs10",
    "created_at": "2026-06-29T10:00:00Z",
    "perfil": {
      "foto_url": "https://storage.../foto.jpg",
      "avatar": "avatar_05",
      "data_nascimento": "1995-03-15",
      "posicao_principal": "Meio-campo",
      "posicao_secundaria": "Atacante"
    }
  }
}
```

---

### 3.7 Atualizar Perfil

**`PUT /api/auth/me`** — RF-004 (edicao)

**Header:** `Authorization: Bearer <access_token>`

**Request Body (todos opcionais):**
```json
{
  "nome": "Wesley R. Xavier",
  "apelido": "Xavierinho",
  "foto_url": "https://storage.../nova_foto.jpg",
  "avatar": "avatar_10",
  "data_nascimento": "1995-03-15",
  "posicao_principal": "Atacante",
  "posicao_secundaria": "Meia-atacante"
}
```

> Apenas os campos enviados serao atualizados. Campos ausentes permanecem inalterados.

**Validacoes:**
| Campo | Regra |
|-------|-------|
| `nome` | 3-100 caracteres se informado |
| `apelido` | Max 50 caracteres se informado |
| `posicao_principal` | Valor valido da lista se informado |
| `posicao_secundaria` | Valor valido da lista se informado |

**Fluxo:**
1. Decorator `@token_required` valida o token
2. Separar campos de `usuarios` (nome, apelido) e campos de `perfis_jogador` (foto, avatar, posicao, etc.)
3. Atualizar cada tabela conforme necessario
4. Atualizar `updated_at` em `usuarios`
5. Retornar dados atualizados

**Response 200:**
```json
{
  "message": "Perfil atualizado com sucesso",
  "usuario": { ... }
}
```

---

### 3.8 Alterar Senha

**`PUT /api/auth/alterar-senha`**

**Header:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "senha_atual": "MinhaSenh@123",
  "nova_senha": "NovaSenha@456"
}
```

**Validacoes:**
| Campo | Regra | Erro |
|-------|-------|------|
| `senha_atual` | Obrigatorio, deve conferir com hash atual | `"Senha atual incorreta"` |
| `nova_senha` | Obrigatorio, criterios de seguranca, diferente da atual | `"A nova senha deve ser diferente da atual"` |

**Fluxo:**
1. Decorator `@token_required`
2. Verificar `senha_atual` com bcrypt
3. Validar `nova_senha` (criterios)
4. Gerar novo hash
5. Atualizar `senha_hash` e `updated_at`

**Response 200:**
```json
{
  "message": "Senha alterada com sucesso"
}
```

---

## 4. DECORATOR @token_required

Decorator aplicado em todas as rotas protegidas. Deve ser implementado em `app/utils/decorators.py`.

**Comportamento:**
1. Extrair token do header `Authorization: Bearer <token>`
2. Decodificar com `PyJWT` usando a `SECRET_KEY`
3. Verificar expiracao (`exp`)
4. Verificar tipo (`type == "access"`)
5. Injetar `user_id` no contexto da requisicao (via `g.user_id`)
6. Se invalido -> retornar `401 {"error": "Token invalido ou expirado"}`

**Uso:**
```python
@auth_bp.route('/me', methods=['GET'])
@token_required
def get_perfil():
    user_id = g.user_id
    # ...
```

---

## 5. UTILITARIOS JWT (app/utils/jwt_utils.py)

### 5.1 Geracao de Tokens

```python
def gerar_access_token(user_id: int) -> str:
    payload = {
        "sub": user_id,
        "type": "access",
        "iat": datetime.utcnow(),
        "exp": datetime.utcnow() + timedelta(minutes=15)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")

def gerar_refresh_token(user_id: int) -> str:
    payload = {
        "sub": user_id,
        "type": "refresh",
        "iat": datetime.utcnow(),
        "exp": datetime.utcnow() + timedelta(days=30)
    }
    return jwt.encode(payload, REFRESH_SECRET_KEY, algorithm="HS256")
```

### 5.2 Chaves Secretas

| Variavel | Descricao | Onde Configurar |
|----------|-----------|-----------------|
| `SECRET_KEY` | Chave para access tokens | `.env` -> `JWT_SECRET_KEY` |
| `REFRESH_SECRET_KEY` | Chave separada para refresh tokens | `.env` -> `JWT_REFRESH_SECRET_KEY` |

> **IMPORTANTE:** Chaves DIFERENTES para access e refresh. Se uma vazar, a outra permanece segura.

---

## 6. REGRAS DE SEGURANCA

### 6.1 Senha

| Criterio | Regra |
|----------|-------|
| Tamanho minimo | 8 caracteres |
| Letra maiuscula | Pelo menos 1 |
| Numero | Pelo menos 1 |
| Caractere especial | Pelo menos 1 (`@#$%^&+=!`) |
| Hash | bcrypt com salt automatico (cost factor 12) |

### 6.2 Rate Limiting (proteção contra brute force)

| Endpoint | Limite |
|----------|--------|
| `POST /api/auth/login` | 5 tentativas por minuto por IP |
| `POST /api/auth/esqueci-senha` | 3 tentativas por minuto por IP |
| `POST /api/auth/registro` | 3 tentativas por minuto por IP |

**Implementacao:** `Flask-Limiter` com backend em memoria (adequado para VPS unica).

### 6.3 Protecoes Gerais

- Nunca retornar `senha_hash` em nenhuma response
- Mensagens de erro genericas para login (nao indicar se usuario existe)
- Tokens de reset de senha: uso unico, expiracao 1 hora
- Emails normalizados para lowercase antes de salvar/comparar
- Username normalizado para lowercase antes de salvar/comparar

---

## 7. CONFIGURACOES (app/config.py — complemento ao spec-banco)

```python
import os

class Config:
    # ... configs de banco (ja definidas no spec-banco) ...

    # JWT
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY')
    JWT_REFRESH_SECRET_KEY = os.environ.get('JWT_REFRESH_SECRET_KEY')
    JWT_ACCESS_TOKEN_EXPIRES = 15 * 60          # 15 minutos em segundos
    JWT_REFRESH_TOKEN_EXPIRES = 30 * 24 * 3600  # 30 dias em segundos

    # Bcrypt
    BCRYPT_COST_FACTOR = 12

    # Rate Limiting
    RATELIMIT_DEFAULT = "60/minute"
```

---

## 8. DEPENDENCIAS ADICIONAIS (acrescentar ao requirements.txt)

```
PyJWT==2.9.*
bcrypt==4.2.*
Flask-Limiter==3.8.*
```

---

## 9. VARIAVEIS DE AMBIENTE (.env)

```env
# Banco de dados
DATABASE_URL=postgresql://usuario:senha@localhost:5432/futebol_app

# JWT (gerar com: python -c "import secrets; print(secrets.token_hex(32))")
JWT_SECRET_KEY=<gerar_chave_aleatoria_64_chars>
JWT_REFRESH_SECRET_KEY=<gerar_chave_aleatoria_64_chars_diferente>

# Email (para recuperacao de senha)
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=<email>
MAIL_PASSWORD=<app_password>
```

---

## 10. RESUMO DOS ENDPOINTS

| Metodo | Rota | Autenticado | Descricao | RF |
|--------|------|-------------|-----------|-----|
| POST | `/api/auth/registro` | Nao | Cadastrar novo usuario | RF-001 |
| POST | `/api/auth/login` | Nao | Autenticar usuario | RF-002 |
| POST | `/api/auth/refresh` | Nao* | Renovar access token | - |
| POST | `/api/auth/esqueci-senha` | Nao | Solicitar reset de senha | RF-003 |
| POST | `/api/auth/redefinir-senha` | Nao | Redefinir senha com token | RF-003 |
| GET | `/api/auth/me` | Sim | Obter perfil logado | RF-004 |
| PUT | `/api/auth/me` | Sim | Atualizar perfil | RF-004 |
| PUT | `/api/auth/alterar-senha` | Sim | Alterar senha (logado) | - |

> *Refresh usa o refresh_token no body, nao o access_token no header.

---

## 11. ORDEM DE IMPLEMENTACAO

1. `app/utils/jwt_utils.py` — Funcoes de geracao/validacao de tokens
2. `app/utils/decorators.py` — Decorator `@token_required`
3. `app/services/auth_service.py` — Logica de negocio (hash, validacao, queries)
4. `app/blueprints/auth/__init__.py` — Blueprint registration
5. `app/blueprints/auth/routes.py` — Endpoints na ordem:
   - `POST /registro`
   - `POST /login`
   - `POST /refresh`
   - `GET /me`
   - `PUT /me`
   - `PUT /alterar-senha`
   - `POST /esqueci-senha`
   - `POST /redefinir-senha`
6. Registrar blueprint no `create_app()`
7. Configurar Flask-Limiter no `create_app()`
