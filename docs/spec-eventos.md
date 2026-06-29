# SPEC - MODULO DE EVENTOS

**Projeto:** Sistema de Gerenciamento de Grupos de Futebol Amador  
**Stack:** Flask + Flask-SQLAlchemy + JWT  
**Requisitos:** RF-017 a RF-024  
**Data:** 2026-06-29

---

## 1. ENDPOINTS

| Metodo | Rota | Permissao | Descricao | RF |
|--------|------|-----------|-----------|-----|
| POST | `/api/grupos/:gid/eventos` | Admin | Criar evento | RF-017 |
| GET | `/api/grupos/:gid/eventos` | Membro | Listar eventos do grupo | RF-020 |
| GET | `/api/grupos/:gid/eventos/:eid` | Membro | Detalhes do evento | RF-020 |
| PUT | `/api/grupos/:gid/eventos/:eid` | Admin | Editar evento | RF-018 |
| PUT | `/api/grupos/:gid/eventos/:eid/cancelar` | Admin | Cancelar evento | RF-019 |
| PUT | `/api/grupos/:gid/eventos/:eid/encerrar` | Admin | Encerrar confirmacoes | RF-023 |
| PUT | `/api/grupos/:gid/eventos/:eid/reabrir` | Admin | Reabrir confirmacoes | - |
| POST | `/api/grupos/:gid/eventos/:eid/presenca` | Membro | Responder presenca | RF-021 |
| GET | `/api/grupos/:gid/eventos/:eid/participantes` | Membro | Listar participantes | RF-024 |

---

## 2. REGRAS

- Apenas admins criam, editam, cancelam e encerram eventos
- Membros aprovados respondem presenca e visualizam
- Presenca so pode ser alterada enquanto `status_confirmacoes = 'aberto'` (RF-022)
- Evento cancelado nao aceita mais nenhuma acao
- Notificacao criada para membros ao criar evento (RF-043)
