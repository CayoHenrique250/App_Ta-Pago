import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  DBHelper._internal();

  factory DBHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gym_app.db');

    return await openDatabase(
      path,
      version: 2, // <--- MUDAMOS A VERSÃO DE 1 PARA 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // <--- ADICIONAMOS O MÉTODO DE UPGRADE
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela Usuário (Já com a nova coluna)
    await db.execute('''
      CREATE TABLE usuario(
        id INTEGER PRIMARY KEY,
        nome TEXT,
        idade INTEGER,
        altura REAL,
        peso REAL,
        foto_path TEXT
      )
    ''');
    
    // Insere usuário padrão
    await db.execute("INSERT INTO usuario(id, nome, idade, altura, peso, foto_path) VALUES (1, 'Monstro', 25, 1.75, 70.0, NULL)");

    // Tabela Treinos
    await db.execute('''
      CREATE TABLE treinos(
        id TEXT PRIMARY KEY,
        nome TEXT
      )
    ''');

    // Tabela Treino Dias
    await db.execute('''
      CREATE TABLE treino_dias(
        treino_id TEXT,
        dia INTEGER,
        FOREIGN KEY(treino_id) REFERENCES treinos(id) ON DELETE CASCADE
      )
    ''');

    // Tabela Exercícios
    await db.execute('''
      CREATE TABLE exercicios(
        id TEXT PRIMARY KEY,
        treino_id TEXT,
        nome TEXT,
        series TEXT,
        repeticoes TEXT,
        peso TEXT,
        image_url TEXT,
        FOREIGN KEY(treino_id) REFERENCES treinos(id) ON DELETE CASCADE
      )
    ''');

    // Tabela Histórico
    await db.execute('''
      CREATE TABLE historico(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT,
        foto_path TEXT
      )
    ''');

    // Tabela Checkpoints Diários
    await db.execute('''
      CREATE TABLE checkpoints_diarios(
        exercicio_id TEXT PRIMARY KEY
      )
    ''');
  }

  // Lógica para atualizar quem tem a versão antiga (versão 1) para a nova (versão 2)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adiciona a coluna foto_path na tabela usuario se ela não existir
      await db.execute("ALTER TABLE usuario ADD COLUMN foto_path TEXT");
    }
  }
}