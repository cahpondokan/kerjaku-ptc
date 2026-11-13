import 'package:lembur/core/database/app_database.dart';
import 'package:lembur/features/duty/domain/duty_entry.dart';
import 'package:sqflite/sqflite.dart';

class DutyRepository {
  DutyRepository({Future<Database> Function()? database})
    : _database = database ?? (() => AppDatabase.instance.database);
  final Future<Database> Function() _database;
  Future<List<DutyEntry>> getAll() async {
    final db = await _database();
    final rows = await db.query(
      'duty_entries',
      orderBy: 'request_date DESC, updated_at DESC',
    );
    return rows.map(DutyEntry.fromMap).toList();
  }

  Future<void> save(DutyEntry entry) async {
    final db = await _database();
    // REPLACE deletes the parent first and would cascade-delete its scans.
    await db.transaction((txn) async {
      final changed = await txn.update(
        'duty_entries',
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      if (changed == 0) await txn.insert('duty_entries', entry.toMap());
    });
  }

  Future<void> delete(String id) async {
    final db = await _database();
    await db.delete('duty_entries', where: 'id = ?', whereArgs: [id]);
  }
}
