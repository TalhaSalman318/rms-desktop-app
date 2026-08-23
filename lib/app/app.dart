import 'package:flutter/material.dart';

import '../data/database/sqlite_database_service.dart';
import '../features/authentication/presentation/auth_gate.dart';
import 'app_theme.dart';

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key, this.databaseService});

  final SqliteDatabaseService? databaseService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Management & POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: AuthGate(databaseService: databaseService),
    );
  }
}
