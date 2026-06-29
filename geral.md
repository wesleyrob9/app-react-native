```python
# Codificando o arquivo Markdown contendo a especificação técnica detalhada ajustada para Flask + PostgreSQL + React Native.

markdown_content = """# ESPECIFICAÇÃO DE ARQUITETURA TÉCNICA E DIRETRIZES DE DESENVOLVIMENTO

**Projeto:** Sistema de Gerenciamento de Grupos de Futebol Amador (App de Grupos)  
**Abordagem:** Mobile-First (Expansão Web Posterior)  
**Infraestrutura:** VPS Pequena Dedicada (Locaweb)  
**Stack Principal:** Python (Flask) + PostgreSQL + React Native (Expo)

---

## 1. VISÃO GERAL DA ARQUITETURA

Este documento serve como a **Master Spec** (Especificação Mestra) para orientar ferramentas de Inteligência Artificial e desenvolvedores na construção do ecossistema do aplicativo. 

A arquitetura adota o modelo **Cliente-Servidor clássico**, otimizado para ambientes de infraestrutura de baixo custo (VPS com CPU e RAM limitadas). Para garantir interatividade em tempo real sem estourar o limite de conexões ou memória da máquina, a comunicação será híbrida: **REST APIs HTTP** para operações CRUD tradicionais e **WebSockets (via Flask-SocketIO)** dedicados exclusivamente à experiência do sorteio ao vivo.


```

```text
Arquivo gerado com sucesso em: ESPECIFICACAO_ARQUITETURA_MASTER.md


```

+----------------------------------------+
|       React Native Mobile App          |
+----------------------------------------+
| REST API (JSON)      ^ WebSocket (Realtime)
v                      |
+----------------------------------------+
|       WSGI HTTP Server (Gunicorn)      |
|  +----------------------------------+  |
|  | Flask Backend Application        |  |
|  |  - Blueprints (Modulos)          |  |
|  |  - Flask-SocketIO (Event Loop)   |  |
|  |  - Flask-SQLAlchemy (ORM)        |  |
|  +----------------------------------+  |
+----------------------------------------+
| SQL Queries
v
+----------------------------------------+
|       PostgreSQL Database Server       |
+----------------------------------------+

```

---

## 2. STACK TECNOLÓGICA E JUSTIFICATIVAS

### 2.1 Backend: Python & Flask
* **Estrutura Base:** Flask utilizando o padrão *Application Factory* e segregado por *Blueprints* (um blueprint por módulo funcional).
* **Concorrência e Tempo Real:** **Flask-SocketIO** combinado com o worker assíncrono **Gevent** ou **Eventlet** integrado ao Gunicorn. Isso transforma o Flask (originalmente síncrono/WSGI) em um servidor orientado a eventos, permitindo milhares de conexões WebSocket simultâneas com baixo uso de memória RAM.
* **ORM (Camada de Banco):** **Flask-SQLAlchemy** para mapeamento objeto-relacional e **Flask-Migrate** (baseado em Alembic) para versionamento estrutural do banco de dados.

### 2.2 Banco de Dados: PostgreSQL
* Hospedado localmente na mesma VPS (acesso via socket local `localhost` para eliminar latência de rede).
* Utilização estrita de restrições relacionais (Foreign Keys, Cascateamento correto e Índices B-Tree em campos de busca frequente como `email`, `username`, `grupo_id` e `evento_id`).

### 2.3 Frontend: React Native + Expo
* **Interface:** Componentização nativa e otimizada (sem frameworks pesados de UI).
* **Tempo Real:** Biblioteca `socket.io-client` alinhada perfeitamente com a versão do protocolo implementada pelo Flask-SocketIO no backend.
* **Estado:** Gerenciamento de estado leve via **Zustand** para tokens JWT e dados do perfil.

---

## 3. MODELAGEM DE DADOS RELACIONAL (DER LOGÍCO)

Abaixo estão as tabelas e os tipos de dados exatos que a IA deve gerar no script de migração do banco.

### 3.1 Tabela: `usuarios`
| Campo | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id` | SERIAL | PRIMARY KEY | Identificador único |
| `nome` | VARCHAR(100) | NOT NULL | Nome completo |
| `apelido` | VARCHAR(50) | NULL | Nome de guerra no futebol |
| `email` | VARCHAR(150) | UNIQUE, NOT NULL | E-mail corporativo/pessoal |
| `username` | VARCHAR(50) | UNIQUE, NOT NULL | Nick de acesso exclusivo |
| `senha_hash` | VARCHAR(255) | NOT NULL | Hash gerado com Bcrypt |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Data de cadastro |
| `is_active` | BOOLEAN | DEFAULT TRUE | Controle de Soft Delete |

### 3.2 Tabela: `perfis_jogador`
| Campo | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `usuario_id` | INT | PRIMARY KEY, FK (usuarios.id) | Link 1:1 com Usuário |
| `foto_url` | VARCHAR(255) | NULL | URL da imagem salva no Storage |
| `avatar` | VARCHAR(50) | NULL | Identificador do avatar estático |
| `data_nascimento`| DATE | NULL | Data opcional |
| `posicao_principal`| VARCHAR(20) | NOT NULL | Goleiro, Zagueiro, Lateral, etc. |
| `posicao_secundaria`| VARCHAR(20) | NULL | Segunda opção de jogo |

### 3.3 Tabela: `grupos`
| Campo | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id` | SERIAL | PRIMARY KEY | Identificador único |
| `nome` | VARCHAR(100) | NOT NULL | Nome da pelada/grupo |
| `descricao` | TEXT | NULL | Regras internas, Avisos |
| `logo_url` | VARCHAR(255) | NULL | URL do escudo do grupo |
| `cidade` | VARCHAR(100) | NULL | Cidade onde ocorrem os jogos |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Data de criação |

### 3.4 Tabela: `grupo_membros`
| Campo | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `grupo_id` | INT | FK (grupos.id), NOT NULL | Grupo vinculado |
| `usuario_id` | INT | FK (usuarios.id), NOT NULL | Jogador vinculado |
| `papel` | VARCHAR(20) | DEFAULT 'membro' | 'admin' ou 'membro' |
| `status` | VARCHAR(20) | DEFAULT 'pendente' | 'pendente', 'aprovado', 'rejeitado' |
| *Composite Key*| (grupo_id, usuario_id) | PRIMARY KEY | Garante unicidade do vínculo |

### 3.5 Tabela: `avaliacoes_jogador`
| Campo | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `grupo_id` | INT | FK (grupos.id), NOT NULL | Contexto do grupo |
| `usuario_id` | INT | FK (usuarios.id), NOT NULL | Jogador avaliado |
| `estrelas` | INT | CHECK (estrelas BETWEEN 1 AND 5) | Nota técnica do admin |
| *Composite Key*| (grupo_id, usuario_id) | PRIMARY KEY | Nota única por jogador/grupo |

### 3.6 Tabela: `historico_avaliacoes`
| Campo | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id` | SERIAL | PRIMARY KEY | Identificador de auditoria |
| `grupo_id` | INT | FK (grupos.id) | Grupo onde ocorreu |
| `usuario_id` | INT | FK (usuarios.id) | Jogador que teve a nota alterada |
| `admin_id` | INT | FK (usuarios.id) | Administrador executor |
| `avaliacao_anterior`| INT | NULL | Estrelas antigas |
| `avaliacao_nova` | INT | NOT NULL | Novas estrelas atribuídas |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Data e hora exata da ação |

### 3.7 Tabela: `eventos`
| Campo | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id` | SERIAL | PRIMARY KEY | Identificador do evento |
| `grupo_id` | INT | FK (grupos.id), NOT NULL | Grupo proprietário |
| `nome` | VARCHAR(100) | NOT NULL | Ex: "Pelada de Quarta" |
| `data_evento` | DATE | NOT NULL | Data do jogo |
| `horario` | TIME | NOT NULL | Horário de início |
| `local` | VARCHAR(255) | NOT NULL | Nome do campo/quadra |
| `observacoes` | TEXT | NULL | Ex: "Levar camisa branca e preta" |
| `status_confirmacoes`| VARCHAR(20) | DEFAULT 'aberto' | 'aberto' ou 'encerrado' |
| `is_active` | BOOLEAN | DEFAULT TRUE | Soft delete para manter histórico |

### 3.8 Tabela: `evento_participantes`
| Campo | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `evento_id` | INT | FK (eventos.id) | Evento específico |
| `usuario_id` | INT | FK (usuarios.id) | Jogador |
| `resposta` | VARCHAR(20) | NOT NULL | 'confirmado', 'nao_vou', 'talvez' |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Data da última alteração de status |
| *Composite Key*| (evento_id, usuario_id) | PRIMARY KEY | Garante uma resposta por pessoa |

### 3.9 Tabelas do Módulo de Sorteio (`sorteios`, `times`, `time_jogadores`)
* Relacionamentos encadeados de forma estrita: Um Evento possui um Sorteio Efivado. Um Sorteio possui N Times. Um Time possui N Jogadores (`time_jogadores` resolve a relação n:m com metadados de posição e estrelas congelados no momento do sorteio).

---

## 4. DIRETRIZES DO BACKEND (FLASK)

Para manter o código limpo e permitir que a IA programe sem misturar responsabilidades, o código deve seguir obrigatoriamente a estrutura abaixo:

### 4.1 Estrutura de Pastas Padrão
```text
meu_app_futebol/
│
├── app/
│   ├── __init__.py          # Application Factory Setup
│   ├── config.py            # Variáveis de ambiente e limites da VPS
│   ├── database.py          # Inicialização do SQLAlchemy e DB helpers
│   ├── socketio_setup.py    # Instanciação do Flask-SocketIO
│   │
│   ├── models/              # Modelos do SQLAlchemy (Mapeamento DB)
│   │   ├── usuario.py
│   │   ├── grupo.py
│   │   └── evento.py
│   │
│   ├── blueprints/          # Controladores separados por domínio de negócio
│   │   ├── auth/            # Módulo de Usuários (Login, Registro)
│   │   ├── grupos/          # Módulo de Grupos e Avaliações
│   │   ├── eventos/         # Módulo de Eventos e Listas de Presença
│   │   └── sorteador/       # APIs HTTP de Sorteio e Lógica Base
│   │
│   └── sockets/             # Eventos e Gateways de WebSocket (Tempo Real)
│       └── sorteio_live.py  # RF-034 a RF-039 (Broadcast de sorteios)
│
├── migrations/              # Arquivos gerados pelo Flask-Migrate (Alembic)
├── wsgi.py                  # Ponto de entrada do Gunicorn (gunicorn -k gevent wsgi:app)
├── requirements.txt         # Dependências do Python
└── README.md

```

### 4.2 Regras de Implementação para a IA

1. **Application Factory:** Nunca declare a variável `app = Flask(__name__)` no escopo global de arquivos internos. Use uma função `create_app()` dentro de `app/__init__.py`.
2. **Consultas Seguras:** Proibido uso de SQL bruto em formato de string sem sanitização. Use os métodos do SQLAlchemy (`db.session.execute(select(...))`).
3. **Tratamento de Exceções:** Todas as rotas de API devem responder em formato JSON padrão (`{"error": "Mensagem detalhada"}`) com o HTTP Status Code adequado em caso de falha.
4. **Gerenciamento de Escopo de Banco:** Certifique-se de que cada requisição limpa sua sessão ao finalizar para evitar vazamento de memória e travamento do PostgreSQL na VPS (`db.session.remove()` automático pelo Flask).

---

## 5. REGRAS DO MOTOR DE SORTEIO (MÓDULO 6 E 7)

O algoritmo matemático e a comunicação em tempo real devem seguir os parâmetros lógicos descritos abaixo para garantir o equilíbrio dos times e a estabilidade do servidor.

### 5.1 O Algoritmo de Sorteio Balanceado (Python)

Ao receber uma requisição de sorteio balanceado, o backend deve executar uma função pura que processa os jogadores em memória antes de enviar a resposta. O fluxo lógico deve ser:

1. **Filtro Primário:** Buscar apenas usuários da tabela `evento_participantes` com status igual a `'confirmado'` cujo evento possua `status_confirmacoes = 'encerrado'`.
2. **Separação de Goleiros:** Identificar todos os jogadores confirmados cuja `posicao_principal` na tabela `perfis_jogador` seja igual a `'Goleiro'`. Distribuir esses goleiros de forma rotativa entre as listas de cada time criado (Garantindo o **RF-031**).
3. **Ordenação por Força Técnica:** Coletar o restante dos jogadores de linha e buscar a quantidade de `estrelas` de cada um para o grupo atual (tabela `avaliacoes_jogador`). Caso o jogador não possua avaliação registrada, assumir o valor padrão de **3 estrelas**.
4. **Algoritmo de Serpentina (Garantia do RF-029):** Ordenar os jogadores de linha de forma decrescente com base em suas estrelas. Distribuir os jogadores nos times seguindo o padrão de "serpentina" para evitar que o primeiro time fique com todos os melhores.
* *Exemplo para 3 times:* * Rodada 1: Jogador 1 $\rightarrow$ Time A, Jogador 2 $\rightarrow$ Time B, Jogador 3 $\rightarrow$ Time C.
* Rodada 2: Jogador 4 $\rightarrow$ Time C, Jogador 5 $\rightarrow$ Time B, Jogador 6 $\rightarrow$ Time A.




5. **Ajuste Fino por Posição:** Fazer uma validação secundária para garantir que um time não fique sobrecarregado apenas com atacantes ou apenas com zagueiros, trocando posições equivalentes (jogadores com o mesmo número de estrelas) entre times caso necessário.

### 5.2 Otimização do Tempo Real (Evitando Sobrecarga na VPS)

Para cumprir as animações do **Módulo 7 (Sorteio Ao Vivo)** sem derrubar a VPS de baixa performance com milhares de escritas/leituras por segundo, a IA deve programar a seguinte estratégia de WebSocket:

1. Quando o Administrador inicia o sorteio ao vivo, o backend em Python roda o algoritmo completo de uma vez só e gera a lista final com todos os times montados. O resultado fica guardado temporariamente na memória do servidor ou em cache de curta duração.
2. O servidor envia via WebSocket (`emit('sorteio_iniciado', room=grupo_id)`) apenas o sinalizador e os dados completos dos times fechados.
3. **O Frontend simula o Tempo Real:** O aplicativo mobile em React Native recebe o JSON completo dos times e dispara o carrossel gráfico localmente (usando animações do dispositivo). O app "finge" que está escolhendo o jogador na hora, mostrando as fotos girando e revelando um por um respeitando os tempos de animação.
4. Ao final da animação local do front, o resultado oficial é exibido. O administrador clica em "Confirmar Sorteio", disparando uma requisição HTTP REST simples para persistir o resultado nas tabelas `sorteios`, `times` e `time_jogadores` do PostgreSQL.
5. **Resultado:** O banco de dados sofre apenas **1 operação de leitura** e **1 operação de escrita** no final, em vez de centenas de requisições por segundo durante a animação de rotação de fotos.

---

## 6. DIRETRIZES DO FRONTEND (REACT NATIVE)

1. **Separação de Regras de Interface:** Nenhuma tela do aplicativo deve instanciar regras de negócio ou chamadas de fetch diretas no corpo do componente. Toda lógica de rede e manipulação de arrays para o sorteio deve viver dentro de custom hooks personalizados (ex: `useSorteioLive.js`).
2. **Gerenciamento de Ciclo de Vida do WebSocket:** Conexões com o servidor Flask-SocketIO devem ser abertas estritamente no momento em que o usuário entra na tela de acompanhamento de sorteio e **obrigatoriamente fechadas (disconnect)** quando ele sai da tela ou minimiza o aplicativo, liberando os descritores de arquivo e conexões ativas na VPS.

---

## 7. CONFIGURAÇÕES DE PRODUÇÃO PARA VPS PEQUENA (LOCAWEB)

A IA deve gerar os arquivos de configuração do ecossistema de produção levando em consideração as seguintes travas de segurança de infraestrutura:

### 7.1 Configuração do Gunicorn (`gunicorn_config.py`)

Para que o Flask consiga processar WebSockets de forma assíncrona, ele deve rodar com a classe de worker correta do `gevent`:

```python
# gunicorn_config.py
bind = "127.0.0.1:5000"
workers = 2  # Mantido baixo para economizar memória RAM na VPS pequena
worker_class = "gevent"  # Permite o chaveamento assíncrono para Flask-SocketIO
timeout = 120
keepalive = 5

```

### 7.2 Configuração do Banco de Dados PostgreSQL (`postgresql.conf`)

Por padrão, o PostgreSQL vem configurado para servidores parrudos. Em uma VPS pequena compartilhada com a aplicação, ele deve ser limitado para evitar a queda do sistema por falta de memória (Out-Of-Memory Killer):

* `max_connections = 50` (Suficiente para a escala inicial e evita saturação de threads).
* `shared_buffers = 128MB` (Espaço controlado para cache de dados).
* `work_mem = 4MB` (Memória para ordenações internas do algoritmo de sorteio por conexão).

---


```