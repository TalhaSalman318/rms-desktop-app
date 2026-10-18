import 'package:flutter/material.dart';

import '../core/services/api_client.dart';
import '../features/authentication/presentation/auth_gate.dart';
import 'app_theme.dart';

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grillix Restaurant Management & POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: AuthGate(apiClient: apiClient),
    );
  }
}
