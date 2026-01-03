import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/treino_model.dart';
import '../models/exercicio_model.dart';
import '../models/usuario_model.dart';

class TreinoService with ChangeNotifier {
  late UsuarioModelo _usuario;

  List<TreinoModelo> _listaDeTreinos = [];
  Map<DateTime, String?> _historico = {};

  // Getters básicos
  UsuarioModelo get usuario => _usuario;
  List<TreinoModelo> get listaDeTreinos => _listaDeTreinos;
  Map<DateTime, String?> get historicoMap => _historico;
  
  // Getter: Total de treinos
  int get treinosTotais => _historico.length;

  // --- CORREÇÃO 1: Getter para saber se treinou hoje ---
  bool get treinoDeHojeConcluido {
    final hoje = DateTime.now();
    // Cria uma data sem horas/minutos para comparar com a chave do map
    final dataLimpa = DateTime(hoje.year, hoje.month, hoje.day);
    return _historico.containsKey(dataLimpa);
  }
  
  // Getter: Nome do Rank Atual
  String get rankAtual {
    int total = treinosTotais;
    if (total < 5) return "Frango";
    if (total < 15) return "Em Construção";
    if (total < 30) return "Ratão de Academia";
    if (total < 60) return "Monstro";
    return "Olimpo";
  }

  // --- CORREÇÃO 2: Getter para o Próximo Rank ---
  String get proximoRank {
    int total = treinosTotais;
    if (total < 5) return "Em Construção";
    if (total < 15) return "Ratão de Academia";
    if (total < 30) return "Monstro";
    if (total < 60) return "Olimpo";
    return "Nível Máximo";
  }

  // --- CORREÇÃO 3: Getter para Barra de Progresso (0.0 a 1.0) ---
  double get progressoRank {
    int total = treinosTotais;
    
    // Função auxiliar para calcular porcentagem dentro do nível
    double calc(int min, int max) {
      if (total >= max) return 1.0;
      return (total - min) / (max - min);
    }

    if (total < 5) return calc(0, 5);       // De 0 a 5
    if (total < 15) return calc(5, 15);     // De 5 a 15
    if (total < 30) return calc(15, 30);    // De 15 a 30
    if (total < 60) return calc(30, 60);    // De 30 a 60
    return 1.0; // Olimpo (cheio)
  }

  TreinoService() {
    carregarDados();
  }

  // --- CARREGAMENTO DE DADOS ---
  Future<void> carregarDados() async {
    final db = await DBHelper().database;

    // 1. Carregar Usuário
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
      _usuario = UsuarioModelo(nome: 'Atleta', idade: 25, altura: 1.75, peso: 70.0);
    }

    // 2. Carregar Treinos
    final treinosData = await db.query('treinos');
    List<TreinoModelo> listaTemporaria = [];

    for (var t in treinosData) {
      final treinoId = t['id'] as String;
      
      final diasData = await db.query('treino_dias', where: 'treino_id = ?', whereArgs: [treinoId]);
      List<int> dias = diasData.map((d) => d['dia'] as int).toList();

      final exerciciosData = await db.query('exercicios', where: 'treino_id = ?', whereArgs: [treinoId]);
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

      listaTemporaria.add(TreinoModelo(
        id: treinoId,
        nome: t['nome'] as String,
        diasDaSemana: dias,
        exercicios: exercicios,
      ));
    }
    _listaDeTreinos = listaTemporaria;

    // 3. Carregar Histórico
    final historicoData = await db.query('historico');
    _historico = {};
    for (var h in historicoData) {
      final dataStr = h['data'] as String;
      final foto = h['foto_path'] as String?;
      final datePart = DateTime.parse(dataStr);
      final dataLimpa = DateTime(datePart.year, datePart.month, datePart.day);
      _historico[dataLimpa] = foto;
    }

    notifyListeners();
  }

  // --- MÉTODOS DE AÇÃO (CRUD) ---

  Future<void> removerHistorico(DateTime dataSelecionada) async {
    final db = await DBHelper().database;
    
    // Converte a data selecionada para string YYYY-MM-DD para buscar no banco
    // Usamos LIKE para garantir que pegue independente da hora exata salva
    String dataBusca = dataSelecionada.toIso8601String().substring(0, 10); // Ex: "2023-10-25"

    await db.delete(
      'historico', 
      where: "data LIKE ?", 
      whereArgs: ['$dataBusca%'] // O % serve para ignorar o horário (HH:MM:SS)
    );

    // Remove do Map local para atualizar a tela instantaneamente
    final dataLimpa = DateTime(dataSelecionada.year, dataSelecionada.month, dataSelecionada.day);
    _historico.remove(dataLimpa);
    
    notifyListeners();
  }

  // 2. Adicionar treino manual (Data passada)
  Future<void> adicionarHistoricoManual(DateTime dataSelecionada, String? fotoPath) async {
    final db = await DBHelper().database;
    
    // Salva a data passada com um horário fixo (ex: 12:00)
    final dataComHora = dataSelecionada.add(const Duration(hours: 12));

    await db.insert('historico', {
      'data': dataComHora.toIso8601String(),
      'foto_path': fotoPath
    });

    // Atualiza o Map local
    final dataLimpa = DateTime(dataSelecionada.year, dataSelecionada.month, dataSelecionada.day);
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
    await db.update('treinos', {'nome': treino.nome}, where: 'id = ?', whereArgs: [treino.id]);

    await db.delete('treino_dias', where: 'treino_id = ?', whereArgs: [treino.id]);
    for (var dia in treino.diasDaSemana) {
      await db.insert('treino_dias', {'treino_id': treino.id, 'dia': dia});
    }

    await db.delete('exercicios', where: 'treino_id = ?', whereArgs: [treino.id]);
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

  Future<void> marcarTreinoComoConcluido(TreinoModelo treino, Map<String, String> cargasNovas, String? fotoDoDia) async {
    final db = await DBHelper().database;
    final hoje = DateTime.now();

    await db.insert('historico', {
      'data': hoje.toIso8601String(),
      'foto_path': fotoDoDia
    });

    for (var ex in treino.exercicios) {
      if (cargasNovas.containsKey(ex.id)) {
        await db.update(
          'exercicios',
          {'peso': cargasNovas[ex.id]},
          where: 'id = ?',
          whereArgs: [ex.id],
        );
      }
    }
    
    await db.delete('checkpoints_diarios');
    carregarDados();
  }

  Future<void> atualizarPerfil(String nome, int idade, double altura, double peso, String? fotoPath) async {
    final db = await DBHelper().database;
    
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
    
    notifyListeners();
  }

  // --- CHECKPOINTS ---
  Future<void> alternarCheckpoint(String exercicioId, bool status) async {
    final db = await DBHelper().database;
    if (status) {
      await db.insert('checkpoints_diarios', {'exercicio_id': exercicioId});
    } else {
      await db.delete('checkpoints_diarios', where: 'exercicio_id = ?', whereArgs: [exercicioId]);
    }
  }

  Future<List<String>> carregarCheckpointsDoDia() async {
    final db = await DBHelper().database;
    final result = await db.query('checkpoints_diarios');
    return result.map((row) => row['exercicio_id'] as String).toList();
  }
}