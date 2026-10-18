import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RestaurantApp(apiClient: ApiClient()));
}

class MyApp extends RestaurantApp {
  const MyApp({super.key, super.apiClient});
}
