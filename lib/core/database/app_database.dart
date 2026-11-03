import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'lembur_ptc.db');
    _database = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE overtime_entries(
            id TEXT PRIMARY KEY,
            overtime_date TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            actual_hours REAL NOT NULL,
            converted_hours REAL NOT NULL,
            day_type TEXT NOT NULL,
            work_description TEXT NOT NULL,
            approver_position TEXT NOT NULL,
            approver_name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            monthly_wage_basis_cents INTEGER
          )
        ''');
        await createLeaveTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await createLeaveTables(db);
        if (oldVersion < 3) await addOvertimeWageColumn(db);
      },
    );
    return _database!;
  }

  static Future<void> addOvertimeWageColumn(DatabaseExecutor db) async {
    await db.execute(
      'ALTER TABLE overtime_entries ADD COLUMN monthly_wage_basis_cents INTEGER',
    );
  }

  static Future<void> createLeaveTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE leave_entries(
        id TEXT PRIMARY KEY,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        request_date TEXT NOT NULL,
        reason TEXT NOT NULL,
        address TEXT NOT NULL,
        applicant_name TEXT NOT NULL,
        worker_number TEXT NOT NULL,
        aft_name TEXT NOT NULL,
        aft_position TEXT NOT NULL,
        manager_name TEXT NOT NULL,
        manager_position TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE leave_year_balances(
        year INTEGER PRIMARY KEY,
        initial_used INTEGER NOT NULL CHECK(initial_used >= 0 AND initial_used <= 12)
      )
    ''');
    await db.execute('''
      CREATE TABLE leave_defaults(
        id INTEGER PRIMARY KEY CHECK(id = 1),
        reason TEXT NOT NULL,
        address TEXT NOT NULL,
        aft_name TEXT NOT NULL,
        aft_position TEXT NOT NULL
      )
    ''');
  }
}
