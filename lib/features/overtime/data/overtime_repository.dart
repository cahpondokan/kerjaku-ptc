import 'package:lembur/core/database/app_database.dart';
import 'package:lembur/features/overtime/domain/overtime_entry.dart';
import 'package:sqflite/sqflite.dart';

class OvertimeRepository {
  Future<List<OvertimeEntry>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'overtime_entries',
      orderBy: 'overtime_date DESC, start_time DESC',
    );
    return rows.map(OvertimeEntry.fromMap).toList();
  }

  Future<void> save(OvertimeEntry entry) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'overtime_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('overtime_entries', where: 'id = ?', whereArgs: [id]);
  }
}
