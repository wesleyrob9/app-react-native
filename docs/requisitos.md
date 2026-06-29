# ESPECIFICAÇÃO DE REQUISITOS - APP DE GRUPOS DE FUTEBOL

## 1. OBJETIVO
Aplicação web e mobile para gerenciamento de grupos de futebol amador, permitindo organizar jogadores, eventos, confirmações de presença e sorteios de times de forma simples e colaborativa.

---

## 2. MÓDULO DE USUÁRIOS

* **RF-001 - Cadastro de Usuário**
  O sistema deve permitir o cadastro de usuários com os seguintes dados:
  * Nome
  * Apelido (opcional)
  * E-mail
  * Nome de usuário
  * Senha
  * *Regras:* * Nome de usuário deve ser único.
    * E-mail deve ser único.
    * Senha deve atender critérios mínimos de segurança.

* **RF-002 - Login**
  O sistema deve permitir autenticação através de Usuário e senha.

* **RF-003 - Recuperação de Senha**
  O sistema deve permitir recuperação de senha através do e-mail cadastrado.

* **RF-004 - Perfil do Jogador**
  O usuário poderá manter seu perfil atualizado.
  * *Dados do perfil:* Nome, Apelido, Foto do jogador, Avatar, Data de nascimento (opcional), Posição principal, Posição secundária (opcional).
  * *Posições disponíveis:* Goleiro, Zagueiro, Lateral, Volante, Meio-campo, Meia-atacante, Atacante.

---

## 3. MÓDULO DE GRUPOS

* **RF-005 - Criar Grupo**
  O sistema deve permitir que um usuário crie um grupo.
  * *Dados:* Nome do grupo, Descrição, Logo, Cidade (opcional).
  * *Regras:* Ao criar um grupo, o usuário torna-se membro automaticamente e recebe o papel de Administrador.

* **RF-006 - Editar Grupo**
  Administradores poderão editar: Nome, Descrição, Logo e Configurações do grupo.

* **RF-007 - Solicitação de Entrada**
  Usuários poderão solicitar participação em grupos.

* **RF-008 - Aprovação de Participantes**
  Administradores poderão aprovar ou rejeitar solicitações.

* **RF-009 - Administração do Grupo**
  Um grupo poderá possuir um ou mais administradores. Todos os administradores possuem exatamente os mesmos privilégios.

* **RF-010 - Promoção para Administrador**
  Administradores poderão promover membros para administrador. Após promovido, o usuário passa a possuir controle total sobre o grupo.

* **RF-011 - Remoção de Administrador**
  Administradores poderão remover outros administradores.
  * *Regra:* O sistema deve impedir que o grupo fique sem administradores.

* **RF-012 - Remoção de Membro**
  Administradores poderão remover membros do grupo.

* **RF-013 - Saída do Grupo**
  Membros poderão sair do grupo.
  * *Regra:* Caso seja o último administrador, a saída não será permitida enquanto outro administrador não for definido.

---

## 4. MÓDULO DE AVALIAÇÃO DOS JOGADORES

* **RF-014 - Classificação por Estrelas**
  Administradores poderão atribuir classificação técnica aos jogadores.
  * *Escala:* 1 a 5 estrelas.

* **RF-015 - Alteração de Classificação**
  Administradores poderão alterar a quantidade de estrelas dos jogadores.

* **RF-016 - Histórico de Avaliações**
  O sistema deverá armazenar: Jogador avaliado, Avaliação anterior, Nova avaliação, Administrador responsável e Data da alteração.

---

## 5. MÓDULO DE EVENTOS

* **RF-017 - Criar Evento**
  Administradores poderão criar eventos.
  * *Dados:* Nome do evento, Data, Horário, Local, Observações.

* **RF-018 - Editar Evento**
  Administradores poderão editar eventos futuros.

* **RF-019 - Cancelar Evento**
  Administradores poderão cancelar eventos.

* **RF-020 - Visualizar Eventos**
  Todos os membros do grupo poderão visualizar eventos do grupo.

* **RF-021 - Resposta de Presença**
  Membros poderão responder: Confirmado, Não vou participar, Talvez.

* **RF-022 - Alteração de Presença**
  O participante poderá alterar sua resposta enquanto o evento estiver aberto.

* **RF-023 - Encerramento das Confirmações**
  Administradores poderão encerrar as confirmações de presença.
  * *Regra:* Após encerramento, apenas participantes confirmados estarão aptos ao sorteio.

* **RF-024 - Lista de Participantes**
  O sistema deverá exibir: Confirmados, Não confirmados, Talvez, Total de participantes.

---

## 6. MÓDULO DE SORTEIO

* **RF-025 - Criar Sorteio**
  Administradores poderão iniciar um sorteio vinculado a um evento.

* **RF-026 - Configuração do Sorteio**
  Antes de iniciar o sorteio deverão ser definidos: Quantidade de times, Nome dos times, Quantidade máxima de jogadores por time, Quantidade de goleiros por time (opcional).

* **RF-027 - Modalidade do Sorteio**
  O administrador deverá escolher:
  * *Sorteio Aleatório:* Distribuição totalmente aleatória.
  * *Sorteio Balanceado:* Distribuição considerando equilíbrio técnico.

* **RF-028 - Seleção dos Participantes**
  O sistema deverá utilizar apenas participantes confirmados.

* **RF-029 - Sorteio Balanceado**
  O sistema deverá considerar: Quantidade de estrelas, Distribuição de goleiros, Distribuição de posições.
  * *Objetivo:* Manter os times tecnicamente equilibrados.

* **RF-030 - Sorteio Aleatório**
  O sistema não deverá considerar estrelas, posições ou histórico.

* **RF-031 - Distribuição de Goleiros**
  No modo balanceado, o sistema deverá tentar distribuir goleiros igualmente entre os times.

* **RF-032 - Reiniciar Sorteio**
  Administradores poderão refazer um sorteio antes da confirmação final.

* **RF-033 - Confirmar Sorteio**
  Após confirmação, o resultado ficará registrado no evento.

---

## 7. MÓDULO DE SORTEIO EM TEMPO REAL

* **RF-034 - Sorteio Ao Vivo**
  O sistema deverá permitir a execução do sorteio em tempo real.

* **RF-035 - Acompanhamento em Tempo Real**
  Todos os membros do grupo poderão acompanhar o sorteio simultaneamente.

* **RF-036 - Atualização Automática**
  A tela deverá atualizar automaticamente sem necessidade de recarregar a página.

* **RF-037 - Animação de Sorteio**
  Durante o sorteio:
  * Fotos dos jogadores deverão ser exibidas em formato de carrossel.
  * O sistema deverá selecionar um jogador visualmente antes de ser atribuído ao time.

* **RF-038 - Exibição Parcial**
  Durante o sorteio deverá ser exibido: Times criados, Jogadores já sorteados, Quantidade de jogadores por time, Soma das estrelas por time.

* **RF-039 - Exibição Final**
  Ao término do sorteio deverá ser exibido por time: Nome, Logo (opcional), Jogadores, Posições e Total de estrelas.

---

## 8. MÓDULO DE HISTÓRICO

* **RF-040 - Histórico de Eventos**
  O sistema deverá manter histórico de eventos realizados.

* **RF-041 - Histórico de Sorteios**
  O sistema deverá armazenar: Data, Evento, Configuração utilizada, Times gerados.

* **RF-042 - Consulta de Sorteios**
  Membros poderão visualizar sorteios anteriores.

---

## 9. MÓDULO DE NOTIFICAÇÕES

* **RF-043 - Novo Evento:** Notificar membros quando um novo evento for criado.
* **RF-044 - Aprovação no Grupo:** Notificar usuários quando sua solicitação for aprovada.
* **RF-045 - Sorteio Iniciado:** Notificar membros quando um sorteio for iniciado.
* **RF-046 - Sorteio Finalizado:** Notificar membros quando o sorteio for concluído.

---

## 10. REQUISITOS NÃO FUNCIONAIS (RNF)

* **RNF-001:** O sistema deverá funcionar em dispositivos móveis e navegadores web modernos.
* **RNF-002:** O sistema deverá suportar múltiplos grupos simultaneamente.
* **RNF-003:** As informações deverão ser armazenadas de forma segura.
* **RNF-004:** As senhas deverão ser armazenadas utilizando criptografia/hash.
* **RNF-005:** O sistema deverá suportar atualização em tempo real para acompanhamento dos sorteios.
* **RNF-006:** O sistema deverá permitir upload de fotos de perfil e logos de grupos.
* **RNF-007:** O sistema deverá registrar logs de auditoria para ações administrativas.

---

## 11. PRINCIPAIS ENTIDADES DO SISTEMA
1. Usuário
2. PerfilJogador
3. Grupo
4. GrupoMembro
5. Evento
6. EventoParticipante
7. AvaliacaoJogador
8. Sorteio
9. Time
10. TimeJogador
11. Notificacao
12. HistoricoAvaliacao