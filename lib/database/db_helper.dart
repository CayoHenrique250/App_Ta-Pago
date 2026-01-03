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
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

    await db.execute(
      "INSERT INTO usuario(id, nome, idade, altura, peso, foto_path) VALUES (1, 'Monstro', 25, 1.75, 70.0, NULL)",
    );

    await db.execute('''
      CREATE TABLE treinos(
        id TEXT PRIMARY KEY,
        nome TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE treino_dias(
        treino_id TEXT,
        dia INTEGER,
        FOREIGN KEY(treino_id) REFERENCES treinos(id) ON DELETE CASCADE
      )
    ''');

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

    await db.execute('''
      CREATE TABLE historico(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT,
        foto_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE checkpoints_diarios(
        exercicio_id TEXT PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE cargas_temporarias(
        exercicio_id TEXT PRIMARY KEY,
        carga TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE historico_peso(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT,
        peso REAL,
        altura REAL,
        imc REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE historico_cargas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercicio_id TEXT,
        exercicio_nome TEXT,
        data TEXT,
        carga REAL,
        treino_id TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE usuario ADD COLUMN foto_path TEXT");
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS historico_peso(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          data TEXT,
          peso REAL,
          altura REAL,
          imc REAL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS historico_cargas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          exercicio_id TEXT,
          exercicio_nome TEXT,
          data TEXT,
          carga REAL,
          treino_id TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cargas_temporarias(
          exercicio_id TEXT PRIMARY KEY,
          carga TEXT
        )
      ''');
    }
  }
}
