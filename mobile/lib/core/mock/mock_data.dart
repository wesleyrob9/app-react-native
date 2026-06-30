import '../../features/auth/models/user_model.dart';
import '../../features/grupos/models/grupo_model.dart';
import '../../features/eventos/models/evento_model.dart';
import '../../features/sorteio/models/sorteio_model.dart';
import '../../features/notificacoes/models/notificacao_model.dart';
import '../../features/avaliacoes/models/avaliacao_model.dart';

class MockData {
  // Usuário logado
  static final UserModel currentUser = UserModel(
    id: 1,
    nome: 'Wesley Xavier',
    apelido: 'Xavs',
    email: 'wesley@email.com',
    username: 'xavs10',
    posicaoPrincipal: 'Meio',
    posicaoSecundaria: 'Atacante',
  );

  // Lista de usuarios mock
  static final List<UserModel> users = [
    currentUser,
    UserModel(id: 2, nome: 'Carlos Mendes', apelido: 'Carlão', email: 'carlos@email.com', username: 'carlao7', posicaoPrincipal: 'Atacante'),
    UserModel(id: 3, nome: 'Rafael Lima', apelido: 'Rafa', email: 'rafa@email.com', username: 'rafa11', posicaoPrincipal: 'Goleiro'),
    UserModel(id: 4, nome: 'Bruno Silva', email: 'bruno@email.com', username: 'bsilva', posicaoPrincipal: 'Zagueiro'),
    UserModel(id: 5, nome: 'Thiago Costa', apelido: 'Thiagão', email: 'thiago@email.com', username: 'thiagao', posicaoPrincipal: 'Zagueiro'),
    UserModel(id: 6, nome: 'Marcos Pereira', email: 'marcos@email.com', username: 'marcao', posicaoPrincipal: 'Meio'),
    UserModel(id: 7, nome: 'Paulo Henrique', apelido: 'PH', email: 'ph@email.com', username: 'ph10', posicaoPrincipal: 'Atacante'),
    UserModel(id: 8, nome: 'Guilherme Rocha', apelido: 'Gui', email: 'gui@email.com', username: 'gui9', posicaoPrincipal: 'Atacante'),
    UserModel(id: 9, nome: 'Rodrigo Faria', email: 'rodrigo@email.com', username: 'rod', posicaoPrincipal: 'Zagueiro'),
    UserModel(id: 10, nome: 'Lucas Moreira', apelido: 'Lukinha', email: 'lucas@email.com', username: 'lukinha', posicaoPrincipal: 'Meio'),
  ];

  // Membros dos grupos
  static final List<MembroModel> membrosGrupo1 = [
    MembroModel(usuario: users[0], papel: 'admin', estrelas: 4),
    MembroModel(usuario: users[1], papel: 'membro', estrelas: 5),
    MembroModel(usuario: users[2], papel: 'membro', estrelas: 3),
    MembroModel(usuario: users[3], papel: 'admin', estrelas: 4),
    MembroModel(usuario: users[4], papel: 'membro', estrelas: 3),
    MembroModel(usuario: users[5], papel: 'membro', estrelas: 2),
    MembroModel(usuario: users[6], papel: 'membro', estrelas: 4),
    MembroModel(usuario: users[7], papel: 'membro', estrelas: 5),
    MembroModel(usuario: users[8], papel: 'membro', estrelas: 3),
    MembroModel(usuario: users[9], papel: 'membro', estrelas: 4),
  ];

  static final List<MembroModel> membrosGrupo2 = [
    MembroModel(usuario: users[0], papel: 'membro', estrelas: 4),
    MembroModel(usuario: users[1], papel: 'admin', estrelas: 5),
    MembroModel(usuario: users[4], papel: 'membro', estrelas: 3),
    MembroModel(usuario: users[7], papel: 'membro', estrelas: 5),
  ];

  // Pendentes
  static final List<MembroModel> pendenteGrupo1 = [
    MembroModel(usuario: UserModel(id: 11, nome: 'Fernando Souza', email: 'fer@email.com', username: 'fersouz', posicaoPrincipal: 'Atacante'), papel: 'membro'),
    MembroModel(usuario: UserModel(id: 12, nome: 'André Martins', email: 'andre@email.com', username: 'andrem', posicaoPrincipal: 'Zagueiro'), papel: 'membro'),
  ];

  // Grupos
  static final List<GrupoModel> grupos = [
    GrupoModel(
      id: 1,
      nome: 'Pelada de Quarta',
      descricao: 'Nossa pelada toda quarta às 20h no campo do bairro. Camisa branca e preta.',
      cidade: 'São Paulo',
      codigoConvite: 'PQ2024AB',
      totalMembros: 10,
      papel: 'admin',
    ),
    GrupoModel(
      id: 2,
      nome: 'Fut Empresarial',
      descricao: 'Time da empresa, todo sábado de manhã.',
      cidade: 'São Paulo',
      codigoConvite: 'FUEMP22',
      totalMembros: 4,
      papel: 'membro',
    ),
  ];

  // Eventos
  static final List<EventoModel> eventosGrupo1 = [
    EventoModel(
      id: 1,
      grupoId: 1,
      nome: 'Pelada de Quarta - 02/07',
      dataEvento: DateTime(2026, 7, 2),
      horario: '20:00',
      local: 'Campo do Bairro Jardins',
      observacoes: 'Levar camisa branca e preta. Trazer R\$10 pra água.',
      statusConfirmacoes: 'aberto',
      isActive: true,
      totalConfirmados: 7,
      totalNaoVai: 1,
      totalTalvez: 2,
      minhaResposta: 'confirmado',
    ),
    EventoModel(
      id: 2,
      grupoId: 1,
      nome: 'Pelada de Quarta - 09/07',
      dataEvento: DateTime(2026, 7, 9),
      horario: '20:00',
      local: 'Campo do Bairro Jardins',
      statusConfirmacoes: 'aberto',
      isActive: true,
      totalConfirmados: 3,
      totalNaoVai: 0,
      totalTalvez: 1,
    ),
    EventoModel(
      id: 3,
      grupoId: 1,
      nome: 'Pelada Extra - 25/06',
      dataEvento: DateTime(2026, 6, 25),
      horario: '19:30',
      local: 'Campo Sintético Arena Norte',
      statusConfirmacoes: 'encerrado',
      isActive: true,
      totalConfirmados: 10,
      totalNaoVai: 0,
      totalTalvez: 0,
      minhaResposta: 'confirmado',
    ),
  ];

  static final List<EventoModel> eventosGrupo2 = [
    EventoModel(
      id: 4,
      grupoId: 2,
      nome: 'Fut Empresarial - 28/06',
      dataEvento: DateTime(2026, 6, 28),
      horario: '09:00',
      local: 'Clube dos Funcionários',
      statusConfirmacoes: 'encerrado',
      isActive: true,
      totalConfirmados: 4,
      totalNaoVai: 0,
      totalTalvez: 0,
      minhaResposta: 'confirmado',
    ),
  ];

  // Participantes evento 1
  static final List<ParticipanteModel> participantesEvento1 = [
    ParticipanteModel(usuario: users[0], resposta: 'confirmado'),
    ParticipanteModel(usuario: users[1], resposta: 'confirmado'),
    ParticipanteModel(usuario: users[2], resposta: 'confirmado'),
    ParticipanteModel(usuario: users[3], resposta: 'confirmado'),
    ParticipanteModel(usuario: users[4], resposta: 'confirmado'),
    ParticipanteModel(usuario: users[5], resposta: 'confirmado'),
    ParticipanteModel(usuario: users[6], resposta: 'confirmado'),
    ParticipanteModel(usuario: users[7], resposta: 'nao_vou'),
    ParticipanteModel(usuario: users[8], resposta: 'talvez'),
    ParticipanteModel(usuario: users[9], resposta: 'talvez'),
  ];

  // Sorteio do evento 3
  static final SorteioModel sorteioEvento3 = SorteioModel(
    id: 1,
    eventoId: 3,
    modalidade: 'balanceado',
    qtdTimes: 2,
    status: 'confirmado',
    times: [
      TimeModel(
        id: 1,
        nome: 'Time A',
        ordem: 1,
        jogadores: [
          JogadorSorteadoModel(usuario: users[1], posicao: 'Atacante', estrelas: 5, ehGoleiro: false),
          JogadorSorteadoModel(usuario: users[6], posicao: 'Atacante', estrelas: 4, ehGoleiro: false),
          JogadorSorteadoModel(usuario: users[0], posicao: 'Meio', estrelas: 4, ehGoleiro: false),
          JogadorSorteadoModel(usuario: users[4], posicao: 'Zagueiro', estrelas: 3, ehGoleiro: false),
          JogadorSorteadoModel(usuario: users[2], posicao: 'Goleiro', estrelas: 3, ehGoleiro: true),
        ],
      ),
      TimeModel(
        id: 2,
        nome: 'Time B',
        ordem: 2,
        jogadores: [
          JogadorSorteadoModel(usuario: users[7], posicao: 'Atacante', estrelas: 5, ehGoleiro: false),
          JogadorSorteadoModel(usuario: users[9], posicao: 'Meio', estrelas: 4, ehGoleiro: false),
          JogadorSorteadoModel(usuario: users[3], posicao: 'Zagueiro', estrelas: 4, ehGoleiro: false),
          JogadorSorteadoModel(usuario: users[8], posicao: 'Zagueiro', estrelas: 3, ehGoleiro: false),
          JogadorSorteadoModel(usuario: users[5], posicao: 'Meio', estrelas: 2, ehGoleiro: false),
        ],
      ),
    ],
  );

  // Notificações
  static final List<NotificacaoModel> notificacoes = [
    NotificacaoModel(
      id: 1,
      tipo: 'novo_evento',
      titulo: 'Novo evento criado',
      mensagem: 'Pelada de Quarta - 09/07 foi criada no grupo Pelada de Quarta.',
      lida: false,
      criadoEm: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificacaoModel(
      id: 2,
      tipo: 'sorteio_finalizado',
      titulo: 'Sorteio confirmado!',
      mensagem: 'O sorteio para Pelada Extra - 25/06 foi confirmado. Confira os times!',
      lida: false,
      criadoEm: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificacaoModel(
      id: 3,
      tipo: 'aprovacao_grupo',
      titulo: 'Aprovado no grupo',
      mensagem: 'Sua solicitação para o grupo Fut Empresarial foi aprovada.',
      lida: true,
      criadoEm: DateTime.now().subtract(const Duration(days: 3)),
    ),
    NotificacaoModel(
      id: 4,
      tipo: 'novo_evento',
      titulo: 'Novo evento criado',
      mensagem: 'Fut Empresarial - 28/06 foi criada.',
      lida: true,
      criadoEm: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  // Avaliacoes
  static final List<AvaliacaoModel> avaliacoesGrupo1 = [
    AvaliacaoModel(usuario: users[1], estrelas: 5, grupoId: 1),
    AvaliacaoModel(usuario: users[7], estrelas: 5, grupoId: 1),
    AvaliacaoModel(usuario: users[0], estrelas: 4, grupoId: 1),
    AvaliacaoModel(usuario: users[3], estrelas: 4, grupoId: 1),
    AvaliacaoModel(usuario: users[6], estrelas: 4, grupoId: 1),
    AvaliacaoModel(usuario: users[9], estrelas: 4, grupoId: 1),
    AvaliacaoModel(usuario: users[2], estrelas: 3, grupoId: 1),
    AvaliacaoModel(usuario: users[4], estrelas: 3, grupoId: 1),
    AvaliacaoModel(usuario: users[8], estrelas: 3, grupoId: 1),
    AvaliacaoModel(usuario: users[5], estrelas: 2, grupoId: 1),
  ];
}
