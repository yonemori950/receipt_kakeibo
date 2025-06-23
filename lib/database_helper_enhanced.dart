import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'receipt_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'receipt_kakeibo.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE receipts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            store TEXT,
            date TEXT,
            amount TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  Future<void> insertReceipt(String store, String date, String amount) async {
    final db = await database;
    await db.insert(
      'receipts',
      {
        'store': store, 
        'date': date, 
        'amount': amount,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Receipt>> getReceipts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipts', 
      orderBy: 'id DESC'
    );
    return List.generate(maps.length, (i) => Receipt.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getAllReceipts() async {
    final db = await database;
    return await db.query(
      'receipts',
      orderBy: 'created_at DESC',
    );
  }

  Future<void> deleteReceipt(int id) async {
    final db = await database;
    await db.delete(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateReceipt(int id, String store, String date, String amount) async {
    final db = await database;
    await db.update(
      'receipts',
      {
        'store': store,
        'date': date,
        'amount': amount,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
} 