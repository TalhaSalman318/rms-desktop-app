import 'package:flutter_test/flutter_test.dart';
import 'package:rms_desktop_app/data/database/sqlite_database_service.dart';
import 'package:rms_desktop_app/features/authentication/data/authentication_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late SqliteDatabaseService database;
  late AuthenticationService authentication;

  setUp(() {
    database = SqliteDatabaseService.forTesting(inMemoryDatabasePath);
    authentication = AuthenticationService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'creates exactly one initial admin and authenticates securely',
    () async {
      await database.open();
      await authentication.ensureInitialAdmin();
      await authentication.ensureInitialAdmin();

      final admins = await database.query('admins');
      expect(admins, hasLength(1));
      expect(
        admins.single['password'],
        isNot(AuthenticationService.initialPassword),
      );
      expect(
        await authentication.authenticate(
          username: AuthenticationService.initialUsername,
          password: AuthenticationService.initialPassword,
        ),
        isNotNull,
      );
      expect(
        await authentication.authenticate(
          username: 'admin',
          password: 'wrong-password',
        ),
        isNull,
      );
    },
  );

  test('changes password and rejects the old password', () async {
    await authentication.ensureInitialAdmin();
    final admin = await authentication.authenticate(
      username: 'admin',
      password: 'Admin@123',
    );
    expect(admin, isNotNull);

    final changed = await authentication.changePassword(
      adminId: admin!.id!,
      currentPassword: 'Admin@123',
      newPassword: 'NewAdmin@456',
    );
    expect(changed, isTrue);
    expect(
      await authentication.authenticate(
        username: 'admin',
        password: 'Admin@123',
      ),
      isNull,
    );
    expect(
      await authentication.authenticate(
        username: 'admin',
        password: 'NewAdmin@456',
      ),
      isNotNull,
    );
  });
}
