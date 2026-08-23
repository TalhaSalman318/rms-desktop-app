// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rms_desktop_app/app/app_theme.dart';
import 'package:rms_desktop_app/features/authentication/data/authentication_service.dart';
import 'package:rms_desktop_app/features/authentication/presentation/authentication_controller.dart';
import 'package:rms_desktop_app/features/authentication/presentation/login_screen.dart';
import 'package:rms_desktop_app/data/database/sqlite_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late SqliteDatabaseService database;

  setUp(() {
    database = SqliteDatabaseService.forTesting(inMemoryDatabasePath);
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('renders the themed admin login screen', (
    WidgetTester tester,
  ) async {
    final controller = AuthenticationController(
      AuthenticationService(database),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: LoginScreen(controller: controller),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
