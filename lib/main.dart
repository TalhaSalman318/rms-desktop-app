import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/database/sqlite_database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SqliteDatabaseService.instance.open();
  runApp(const RestaurantApp());
}

class MyApp extends RestaurantApp {
  const MyApp({super.key, super.databaseService});
}
