import 'package:lembur/core/database/app_database.dart';
import 'package:lembur/features/leave/domain/leave_entry.dart';
import 'package:sqflite/sqflite.dart';

class LeaveRepository {
  Future<List<LeaveEntry>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'leave_entries',
      orderBy: 'start_date DESC, id DESC',
    );
    return rows.map(LeaveEntry.fromMap).toList();
  }

  Future<Map<int, int>> getInitialBalances() async {
    final db = await AppDatabase.instance.database;
    return {
      for (final row in await db.query('leave_year_balances'))
        row['year']! as int: row['initial_used']! as int,
    };
  }

  Future<LeaveDefaults> getDefaults() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('leave_defaults', where: 'id = 1');
    return rows.isEmpty
        ? const LeaveDefaults()
        : LeaveDefaults.fromMap(rows.first);
  }

  Future<void> save(LeaveEntry entry, LeaveDefaults defaults) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.insert(
        'leave_entries',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'leave_defaults',
        defaults.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> setInitialUsed(int year, int days) async {
    final db = await AppDatabase.instance.database;
    await db.insert('leave_year_balances', {
      'year': year,
      'initial_used': days,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('leave_entries', where: 'id = ?', whereArgs: [id]);
  }
}
