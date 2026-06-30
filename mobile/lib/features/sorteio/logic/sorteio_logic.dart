import 'dart:math';
import '../../auth/models/user_model.dart';
import '../../eventos/models/evento_model.dart';
import '../models/sorteio_model.dart';

// Resultado do sorteio gerado em memória (mock — sem persistência real).
// A tela de resultado lê SorteioLogic.ultimoResultado após executar().
class SorteioLogic {
  static SorteioResultado? ultimoResultado;

  static void executar({
    required List<ParticipanteModel> participantes,
    required int qtdTimes,
    required int jogadoresDeLinha,
    required String modalidade,
    required List<String> nomesDosTimes,
    // userId → bool: false = excluído pelo admin
    Map<int, bool> incluidos = const {},
    // userId → posição substituída pontualmente pelo admin
    Map<int, String?> posicaoOverride = const {},
    // userId → índice do time (0-based): fixado pelo admin antes do draft
    Map<int, int> fixados = const {},
  }) {
    // Filtra apenas confirmados e marcados como incluídos
    final confirmados = participantes.where((p) {
      if (p.resposta != 'confirmado') return false;
      return incluidos[p.usuario.id] ?? true;
    }).toList();

    // Resolve posição efetiva (override tem precedência)
    String posicaoEfetiva(ParticipanteModel p) =>
        posicaoOverride[p.usuario.id] ?? p.usuario.posicaoPrincipal ?? 'Meio';

    final goleiros = confirmados.where((p) => posicaoEfetiva(p) == 'Goleiro').toList();
    final deLinha = confirmados.where((p) => posicaoEfetiva(p) != 'Goleiro').toList();

    final rng = Random();

    // Inicializa times
    final times = List.generate(qtdTimes, (_) => <ParticipanteModel>[]);

    // ── E: Aplica fixados primeiro ──
    final naoFixadosLinha = <ParticipanteModel>[];
    final naoFixadosGoleiro = <ParticipanteModel>[];

    for (final p in deLinha) {
      final timeIdx = fixados[p.usuario.id];
      if (timeIdx != null && timeIdx < qtdTimes) {
        times[timeIdx].add(p);
      } else {
        naoFixadosLinha.add(p);
      }
    }
    for (final p in goleiros) {
      final timeIdx = fixados[p.usuario.id];
      if (timeIdx != null && timeIdx < qtdTimes) {
        times[timeIdx].add(p);
      } else {
        naoFixadosGoleiro.add(p);
      }
    }

    // Calcula vagas restantes de linha por time
    final vagasRestantes = List.generate(
      qtdTimes,
      (i) {
        final fixadosNoTime = times[i].where((p) => posicaoEfetiva(p) != 'Goleiro').length;
        return (jogadoresDeLinha - fixadosNoTime).clamp(0, jogadoresDeLinha);
      },
    );
    final totalVagasRestantes = vagasRestantes.fold(0, (a, b) => a + b);

    // ── D: Balanceado por posição + estrelas ──
    List<ParticipanteModel> linhaParaDraft;
    List<ParticipanteModel> excedentes;

    if (modalidade == 'balanceado') {
      // Separa por posição
      final atacantes = naoFixadosLinha
          .where((p) => posicaoEfetiva(p) == 'Atacante')
          .toList()
        ..sort((a, b) => _estrelas(b.usuario).compareTo(_estrelas(a.usuario)));
      final zagueiros = naoFixadosLinha
          .where((p) => posicaoEfetiva(p) == 'Zagueiro')
          .toList()
        ..sort((a, b) => _estrelas(b.usuario).compareTo(_estrelas(a.usuario)));
      final meios = naoFixadosLinha
          .where((p) => posicaoEfetiva(p) == 'Meio')
          .toList()
        ..sort((a, b) => _estrelas(b.usuario).compareTo(_estrelas(a.usuario)));
      final outros = naoFixadosLinha
          .where((p) => !['Atacante', 'Zagueiro', 'Meio'].contains(posicaoEfetiva(p)))
          .toList()
        ..sort((a, b) => _estrelas(b.usuario).compareTo(_estrelas(a.usuario)));

      // Passe 1: garante 1 Atacante e 1 Zagueiro por time (snake draft por posição)
      final prioridade = <ParticipanteModel>[];
      final usados = <ParticipanteModel>{};

      void snakePorPosicao(List<ParticipanteModel> pool, int porTime) {
        int idx = 0;
        bool dir = true;
        int count = 0;
        while (count < porTime * qtdTimes && idx < pool.length) {
          final p = pool[idx];
          if (!usados.contains(p)) {
            prioridade.add(p);
            usados.add(p);
            count++;
          }
          if (dir) {
            idx++;
          } else {
            idx++;
          }
        }
      }

      // Distribui 1 atacante e 1 zagueiro por time no snake
      final atacantesPorTime = (atacantes.length / qtdTimes).floor().clamp(0, 1);
      final zagueirosPorTime = (zagueiros.length / qtdTimes).floor().clamp(0, 1);
      snakePorPosicao(atacantes, atacantesPorTime);
      snakePorPosicao(zagueiros, zagueirosPorTime);

      // Passe 2: completa com meios, outros, e restantes de posições prioritárias
      final resto = [
        ...meios,
        ...outros,
        ...atacantes.where((p) => !usados.contains(p)),
        ...zagueiros.where((p) => !usados.contains(p)),
      ]..sort((a, b) => _estrelas(b.usuario).compareTo(_estrelas(a.usuario)));

      linhaParaDraft = [...prioridade, ...resto];
      final selecionados = linhaParaDraft.take(totalVagasRestantes).toList();
      excedentes = linhaParaDraft.skip(totalVagasRestantes).toList();
      linhaParaDraft = selecionados;
    } else {
      // Aleatório
      naoFixadosLinha.shuffle(rng);
      linhaParaDraft = naoFixadosLinha.take(totalVagasRestantes).toList();
      excedentes = naoFixadosLinha.skip(totalVagasRestantes).toList();
    }

    // ── Snake draft para jogadores de linha não-fixados ──
    bool direcaoNormal = true;
    int timeIdx = 0;
    // Começa pelo time com mais vagas restantes
    timeIdx = vagasRestantes.indexOf(vagasRestantes.reduce((a, b) => a > b ? a : b));

    for (final jogador in linhaParaDraft) {
      // Pula times que já atingiram a cota de linha
      int tentativas = 0;
      while (tentativas < qtdTimes) {
        final linhaNoTime = times[timeIdx].where((p) => posicaoEfetiva(p) != 'Goleiro').length;
        if (linhaNoTime < jogadoresDeLinha) break;
        if (direcaoNormal) {
          timeIdx = (timeIdx + 1) % qtdTimes;
        } else {
          timeIdx = (timeIdx - 1 + qtdTimes) % qtdTimes;
        }
        tentativas++;
      }
      times[timeIdx].add(jogador);

      // Avança direção
      if (direcaoNormal) {
        timeIdx++;
        if (timeIdx >= qtdTimes) {
          timeIdx = qtdTimes - 1;
          direcaoNormal = false;
        }
      } else {
        timeIdx--;
        if (timeIdx < 0) {
          timeIdx = 0;
          direcaoNormal = true;
        }
      }
    }

    // ── Distribui goleiros não-fixados: 1 por time, excedentes são notificados ──
    naoFixadosGoleiro.shuffle(rng);
    final goleirosExcedentes = <UserModel>[];
    for (int i = 0; i < naoFixadosGoleiro.length; i++) {
      if (i < qtdTimes) {
        times[i].add(naoFixadosGoleiro[i]);
      } else {
        goleirosExcedentes.add(naoFixadosGoleiro[i].usuario);
      }
    }

    // ── Converte para modelo ──
    final timesModel = List.generate(qtdTimes, (i) {
      final jogadoresModel = times[i].map((p) {
        final ehGoleiro = posicaoEfetiva(p) == 'Goleiro';
        return JogadorSorteadoModel(
          usuario: p.usuario,
          posicao: posicaoEfetiva(p),
          estrelas: _estrelas(p.usuario),
          ehGoleiro: ehGoleiro,
        );
      }).toList();

      return TimeModel(
        id: i + 1,
        nome: nomesDosTimes[i],
        ordem: i + 1,
        jogadores: jogadoresModel,
      );
    });

    ultimoResultado = SorteioResultado(
      modalidade: modalidade,
      qtdTimes: qtdTimes,
      jogadoresDeLinha: jogadoresDeLinha,
      times: timesModel,
      excedentes: excedentes.map((p) => p.usuario).toList(),
      goleirosExcedentes: goleirosExcedentes,
    );
  }

  static int _estrelas(UserModel u) {
    const estrelasPorId = {1: 4, 2: 5, 3: 3, 4: 4, 5: 3, 6: 2, 7: 4, 8: 5, 9: 3, 10: 4};
    return estrelasPorId[u.id] ?? 3;
  }
}

class SorteioResultado {
  final String modalidade;
  final int qtdTimes;
  final int jogadoresDeLinha;
  final List<TimeModel> times;
  // B: jogadores de linha que sobraram
  final List<UserModel> excedentes;
  // C: goleiros além de 1 por time
  final List<UserModel> goleirosExcedentes;

  const SorteioResultado({
    required this.modalidade,
    required this.qtdTimes,
    required this.jogadoresDeLinha,
    required this.times,
    required this.excedentes,
    required this.goleirosExcedentes,
  });
}
