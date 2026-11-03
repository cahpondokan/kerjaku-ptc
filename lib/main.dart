import 'package:flutter/material.dart';
import 'package:lembur/app/app.dart';
import 'package:lembur/core/database/app_database.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await AppDatabase.instance.database;
  runApp(const KerjaKuBootstrap());
}
