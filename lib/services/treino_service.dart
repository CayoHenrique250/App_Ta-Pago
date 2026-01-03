import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/treino_model.dart';
import '../models/exercicio_model.dart';
import '../models/usuario_model.dart';
import '../models/peso_model.dart';
import '../models/carga_model.dart';

class TreinoService with ChangeNotifier {
  UsuarioModelo _usuario = UsuarioModelo(
    nome: 'Atleta',
    idade: 25,
    altura: 1.75,
    peso: 70.0,
  );

  List<TreinoModelo> _listaDeTreinos = [];
  Map<DateTime, String?> _historico = {};
  List<PesoModelo> _historicoPeso = [];

  UsuarioModelo get usuario => _usuario;
  List<TreinoModelo> get listaDeTreinos => _listaDeTreinos;
  Map<DateTime, String?> get historicoMap => _historico;
  List<PesoModelo> get historicoPeso => _historicoPeso;

  int get treinosTotais => _historico.length;

  bool get treinoDeHojeConcluido {
    final hoje = DateTime.now();
    final dataLimpa = DateTime(hoje.year, hoje.month, hoje.day);
    return _historico.containsKey(dataLimpa);
  }

  String get rankAtual {
    int total = treinosTotais;
    if (total < 5) return "Frango";
    if (total < 15) return "Em Construção";
    if (total < 30) return "Ratão de Academia";
    if (total < 60) return "Monstro";
    return "Olimpo";
  }

  String get proximoRank {
    int total = treinosTotais;
    if (total < 5) return "Em Construção";
    if (total < 15) return "Ratão de Academia";
    if (total < 30) return "Monstro";
    if (total < 60) return "Olimpo";
    return "Nível Máximo";
  }

  double get progressoRank {
    int total = treinosTotais;

    double calc(int min, int max) {
      if (total >= max) return 1.0;
      return (total - min) / (max - min);
    }

    if (total < 5) return calc(0, 5);
    if (total < 15) return calc(5, 15);
    if (total < 30) return calc(15, 30);
    if (total < 60) return calc(30, 60);
    return 1.0;
  }

  TreinoService() {
    carregarDados();
  }

  Future<void> carregarDados() async {
    final db = await DBHelper().database;

    final userList = await db.query('usuario');
    if (userList.isNotEmpty) {
      final u = userList.first;
      _usuario = UsuarioModelo(
        nome: u['nome'] as String,
        idade: u['idade'] as int,
        altura: u['altura'] as double,
        peso: u['peso'] as double,
        fotoPath: u['foto_path'] as String?,
      );
    } else {
      _usuario = UsuarioModelo(
        nome: 'Atleta',
        idade: 25,
        altura: 1.75,
        peso: 70.0,
      );
    }

    final treinosData = await db.query('treinos');
    List<TreinoModelo> listaTemporaria = [];

    for (var t in treinosData) {
      final treinoId = t['id'] as String;

      final diasData = await db.query(
        'treino_dias',
        where: 'treino_id = ?',
        whereArgs: [treinoId],
      );
      List<int> dias = diasData.map((d) => d['dia'] as int).toList();

      final exerciciosData = await db.query(
        'exercicios',
        where: 'treino_id = ?',
        whereArgs: [treinoId],
      );
      List<ExercicioModelo> exercicios = exerciciosData.map((e) {
        return ExercicioModelo(
          id: e['id'] as String,
          nome: e['nome'] as String,
          series: e['series'] as String,
          repeticoes: e['repeticoes'] as String,
          peso: e['peso'] as String,
          imageUrl: e['image_url'] as String?,
        );
      }).toList();

      listaTemporaria.add(
        TreinoModelo(
          id: treinoId,
          nome: t['nome'] as String,
          diasDaSemana: dias,
          exercicios: exercicios,
        ),
      );
    }
    _listaDeTreinos = listaTemporaria;

    final historicoData = await db.query('historico');
    _historico = {};
    for (var h in historicoData) {
      final dataStr = h['data'] as String;
      final foto = h['foto_path'] as String?;
      final datePart = DateTime.parse(dataStr);
      final dataLimpa = DateTime(datePart.year, datePart.month, datePart.day);
      _historico[dataLimpa] = foto;
    }

    final pesoData = await db.query('historico_peso', orderBy: 'data DESC');
    _historicoPeso = pesoData.map((p) => PesoModelo.fromMap(p)).toList();

    notifyListeners();
  }

  Future<void> removerHistorico(DateTime dataSelecionada) async {
    final db = await DBHelper().database;

    String dataBusca = dataSelecionada.toIso8601String().substring(0, 10);

    await db.delete(
      'historico',
      where: "data LIKE ?",
      whereArgs: ['$dataBusca%'],
    );

    final dataLimpa = DateTime(
      dataSelecionada.year,
      dataSelecionada.month,
      dataSelecionada.day,
    );
    _historico.remove(dataLimpa);

    notifyListeners();
  }

  Future<void> adicionarHistoricoManual(
    DateTime dataSelecionada,
    String? fotoPath,
  ) async {
    final db = await DBHelper().database;

    final dataComHora = dataSelecionada.add(const Duration(hours: 12));

    await db.insert('historico', {
      'data': dataComHora.toIso8601String(),
      'foto_path': fotoPath,
    });

    final dataLimpa = DateTime(
      dataSelecionada.year,
      dataSelecionada.month,
      dataSelecionada.day,
    );
    _historico[dataLimpa] = fotoPath;

    notifyListeners();
  }

  Future<void> adicionarTreino(TreinoModelo treino) async {
    final db = await DBHelper().database;
    await db.insert('treinos', {'id': treino.id, 'nome': treino.nome});

    for (var dia in treino.diasDaSemana) {
      await db.insert('treino_dias', {'treino_id': treino.id, 'dia': dia});
    }

    for (var ex in treino.exercicios) {
      await db.insert('exercicios', {
        'id': ex.id,
        'treino_id': treino.id,
        'nome': ex.nome,
        'series': ex.series,
        'repeticoes': ex.repeticoes,
        'peso': ex.peso,
        'image_url': ex.imageUrl,
      });
    }
    carregarDados();
  }

  Future<void> editarTreino(TreinoModelo treino) async {
    final db = await DBHelper().database;
    await db.update(
      'treinos',
      {'nome': treino.nome},
      where: 'id = ?',
      whereArgs: [treino.id],
    );

    await db.delete(
      'treino_dias',
      where: 'treino_id = ?',
      whereArgs: [treino.id],
    );
    for (var dia in treino.diasDaSemana) {
      await db.insert('treino_dias', {'treino_id': treino.id, 'dia': dia});
    }

    await db.delete(
      'exercicios',
      where: 'treino_id = ?',
      whereArgs: [treino.id],
    );
    for (var ex in treino.exercicios) {
      await db.insert('exercicios', {
        'id': ex.id,
        'treino_id': treino.id,
        'nome': ex.nome,
        'series': ex.series,
        'repeticoes': ex.repeticoes,
        'peso': ex.peso,
        'image_url': ex.imageUrl,
      });
    }
    carregarDados();
  }

  Future<void> removerTreino(String id) async {
    final db = await DBHelper().database;
    await db.delete('treinos', where: 'id = ?', whereArgs: [id]);
    carregarDados();
  }

  Future<void> marcarTreinoComoConcluido(
    TreinoModelo treino,
    Map<String, String> cargasNovas,
    String? fotoDoDia,
  ) async {
    final db = await DBHelper().database;
    final hoje = DateTime.now();

    await db.insert('historico', {
      'data': hoje.toIso8601String(),
      'foto_path': fotoDoDia,
    });

    for (var ex in treino.exercicios) {
      if (cargasNovas.containsKey(ex.id)) {
        final novaCargaStr = cargasNovas[ex.id]!;

        await db.update(
          'exercicios',
          {'peso': novaCargaStr},
          where: 'id = ?',
          whereArgs: [ex.id],
        );

        double? cargaDouble;
        try {
          final cargaLimpa = novaCargaStr
              .replaceAll('kg', '')
              .replaceAll(' ', '')
              .trim();
          cargaDouble = double.parse(cargaLimpa);
        } catch (e) {
          final numeros = novaCargaStr.replaceAll(RegExp(r'[^0-9.]'), '');
          if (numeros.isNotEmpty) {
            cargaDouble = double.tryParse(numeros);
          }
        }

        if (cargaDouble != null && cargaDouble > 0) {
          await db.insert('historico_cargas', {
            'exercicio_id': ex.id,
            'exercicio_nome': ex.nome,
            'data': hoje.toIso8601String(),
            'carga': cargaDouble,
            'treino_id': treino.id,
          });
        }
      }
    }

    await db.delete('checkpoints_diarios');
    await limparCargasTemporarias();
    carregarDados();
  }

  Future<void> atualizarPerfil(
    String nome,
    int idade,
    double altura,
    double peso,
    String? fotoPath,
  ) async {
    final db = await DBHelper().database;

    // Verifica se o peso mudou
    final pesoAnterior = _usuario.peso;
    final alturaAnterior = _usuario.altura;
    final pesoMudou = pesoAnterior != peso || alturaAnterior != altura;

    await db.update(
      'usuario',
      {
        'nome': nome,
        'idade': idade,
        'altura': altura,
        'peso': peso,
        'foto_path': fotoPath,
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    _usuario = UsuarioModelo(
      nome: nome,
      idade: idade,
      altura: altura,
      peso: peso,
      fotoPath: fotoPath,
    );

    if (pesoMudou) {
      final imc = peso / (altura * altura);
      await db.insert('historico_peso', {
        'data': DateTime.now().toIso8601String(),
        'peso': peso,
        'altura': altura,
        'imc': imc,
      });
      await carregarDados();
    } else {
      notifyListeners();
    }
  }

  Future<void> alternarCheckpoint(String exercicioId, bool status) async {
    final db = await DBHelper().database;
    if (status) {
      await db.insert('checkpoints_diarios', {'exercicio_id': exercicioId});
    } else {
      await db.delete(
        'checkpoints_diarios',
        where: 'exercicio_id = ?',
        whereArgs: [exercicioId],
      );
    }
  }

  Future<List<String>> carregarCheckpointsDoDia() async {
    final db = await DBHelper().database;
    final result = await db.query('checkpoints_diarios');
    return result.map((row) => row['exercicio_id'] as String).toList();
  }

  Future<void> salvarCargaTemporaria(String exercicioId, String carga) async {
    final db = await DBHelper().database;
    await db.insert('cargas_temporarias', {
      'exercicio_id': exercicioId,
      'carga': carga,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, String>> carregarCargasTemporarias() async {
    final db = await DBHelper().database;
    final result = await db.query('cargas_temporarias');
    final Map<String, String> cargas = {};
    for (var row in result) {
      cargas[row['exercicio_id'] as String] = row['carga'] as String;
    }
    return cargas;
  }

  Future<void> limparCargasTemporarias() async {
    final db = await DBHelper().database;
    await db.delete('cargas_temporarias');
  }

  Map<String, int> getTreinosPorMes() {
    final agora = DateTime.now();
    final Map<String, int> treinosPorMes = {};

    for (int i = 2; i >= 0; i--) {
      final mesesAtras = agora.month - i;
      final ano = agora.year;
      final mesAjustado = mesesAtras <= 0 ? mesesAtras + 12 : mesesAtras;
      final anoAjustado = mesesAtras <= 0 ? ano - 1 : ano;
      final mes = DateTime(anoAjustado, mesAjustado, 1);
      final chave = '${mes.month.toString().padLeft(2, '0')}/${mes.year}';
      treinosPorMes[chave] = 0;
    }

    for (var data in _historico.keys) {
      final chave = '${data.month.toString().padLeft(2, '0')}/${data.year}';
      if (treinosPorMes.containsKey(chave)) {
        treinosPorMes[chave] = (treinosPorMes[chave] ?? 0) + 1;
      }
    }

    return treinosPorMes;
  }

  int getTreinosMesAtual() {
    final agora = DateTime.now();
    int count = 0;

    for (var data in _historico.keys) {
      if (data.year == agora.year && data.month == agora.month) {
        count++;
      }
    }

    return count;
  }

  List<ExercicioModelo> getTodosExercicios() {
    final List<ExercicioModelo> todosExercicios = [];
    for (var treino in _listaDeTreinos) {
      todosExercicios.addAll(treino.exercicios);
    }
    return todosExercicios;
  }

  int getTreinosUltimaSemana() {
    final agora = DateTime.now();
    final umaSemanaAtras = agora.subtract(const Duration(days: 7));
    int count = 0;

    for (var data in _historico.keys) {
      if (data.isAfter(umaSemanaAtras) &&
          data.isBefore(agora.add(const Duration(days: 1)))) {
        count++;
      }
    }

    return count;
  }

  Future<void> adicionarRegistroPeso(double peso, double altura) async {
    final db = await DBHelper().database;
    final imc = peso / (altura * altura);

    await db.insert('historico_peso', {
      'data': DateTime.now().toIso8601String(),
      'peso': peso,
      'altura': altura,
      'imc': imc,
    });

    await carregarDados();
  }

  Future<void> editarRegistroPeso(
    int id,
    double peso,
    double altura,
    DateTime data,
  ) async {
    final db = await DBHelper().database;
    final imc = peso / (altura * altura);

    await db.update(
      'historico_peso',
      {
        'data': data.toIso8601String(),
        'peso': peso,
        'altura': altura,
        'imc': imc,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await carregarDados();
  }

  Future<void> removerRegistroPeso(int id) async {
    final db = await DBHelper().database;
    await db.delete('historico_peso', where: 'id = ?', whereArgs: [id]);
    await carregarDados();
  }

  Future<List<CargaModelo>> getHistoricoCargasExercicio(
    String exercicioId,
  ) async {
    final db = await DBHelper().database;
    final resultados = await db.query(
      'historico_cargas',
      where: 'exercicio_id = ?',
      whereArgs: [exercicioId],
      orderBy: 'data ASC',
    );
    return resultados.map((r) => CargaModelo.fromMap(r)).toList();
  }

  Future<List<String>> getExerciciosComHistorico() async {
    final db = await DBHelper().database;
    final resultados = await db.rawQuery(
      'SELECT DISTINCT exercicio_id, exercicio_nome FROM historico_cargas ORDER BY exercicio_nome',
    );
    return resultados.map((r) => r['exercicio_id'] as String).toList();
  }

  Future<Map<String, dynamic>> getResumoCargasExercicio(
    String exercicioId,
  ) async {
    final historico = await getHistoricoCargasExercicio(exercicioId);
    if (historico.isEmpty) {
      return {
        'primeira': 0.0,
        'ultima': 0.0,
        'melhor': 0.0,
        'tendencia': 0,
        'percentualProgresso': 0.0,
      };
    }

    final primeira = historico.first.carga;
    final ultima = historico.last.carga;
    final melhor = historico
        .map((c) => c.carga)
        .reduce((a, b) => a > b ? a : b);

    int tendencia = 0;
    if (historico.length >= 2) {
      final penultima = historico[historico.length - 2].carga;
      if (ultima > penultima) {
        tendencia = 1;
      } else if (ultima < penultima) {
        tendencia = -1;
      }
    }

    final percentualProgresso = primeira > 0
        ? ((ultima - primeira) / primeira) * 100
        : 0.0;

    return {
      'primeira': primeira,
      'ultima': ultima,
      'melhor': melhor,
      'tendencia': tendencia,
      'percentualProgresso': percentualProgresso,
      'nome': historico.first.exercicioNome,
    };
  }
}
