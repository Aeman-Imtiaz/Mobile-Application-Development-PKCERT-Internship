import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expenses_v3.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT NOT NULL,
            type TEXT NOT NULL DEFAULT 'cash_out',
            amount REAL NOT NULL,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            paymentMode TEXT NOT NULL DEFAULT 'Cash',
            contactName TEXT,
            date TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await instance.database;
    final data = Map<String, dynamic>.from(expense);
    data['userId'] = _uid;
    return await db.insert('expenses', data);
  }

  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final db = await instance.database;
    return await db.query(
      'expenses',
      where: 'userId = ?',
      whereArgs: [_uid],
      orderBy: 'date DESC, id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> searchExpenses(String query) async {
    final db = await instance.database;
    return await db.query(
      'expenses',
      where: 'userId = ? AND (description LIKE ? OR category LIKE ?)',
      whereArgs: [_uid, '%$query%', '%$query%'],
      orderBy: 'date DESC, id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getExpensesByMonth(String yearMonth) async {
    final db = await instance.database;
    return await db.query(
      'expenses',
      where: 'userId = ? AND date LIKE ?',
      whereArgs: [_uid, '$yearMonth%'],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getCategoryTotals(String yearMonth) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
      WHERE userId = ? AND date LIKE ? AND type = 'cash_out'
      GROUP BY category
      ORDER BY total DESC
    ''', [_uid, '$yearMonth%']);
  }

  Future<Map<String, double>> getTotals() async {
    final db = await instance.database;
    final cashIn = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE userId = ? AND type = 'cash_in'",
      [_uid],
    );
    final cashOut = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE userId = ? AND type = 'cash_out'",
      [_uid],
    );
    final inTotal = (cashIn.first['total'] as num).toDouble();
    final outTotal = (cashOut.first['total'] as num).toDouble();
    return {
      'cashIn': inTotal,
      'cashOut': outTotal,
      'balance': inTotal - outTotal,
    };
  }

  /// Total Cash Out for a specific day (format: 'YYYY-MM-DD')
  Future<double> getTodaySpent(String date) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE userId = ? AND date = ? AND type = 'cash_out'",
      [_uid, date],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ? AND userId = ?', whereArgs: [id, _uid]);
  }
}