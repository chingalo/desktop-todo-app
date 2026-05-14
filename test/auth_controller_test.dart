import 'package:dhis_todo/data/database.dart';
import 'package:dhis_todo/state/auth_controller.dart';
import 'package:dhis_todo/services/crypto_utils.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dhis_todo/state/in_memory_session_store.dart';

void main() {
  late AppDatabase db;
  late InMemorySessionStore session;
  late AuthController auth;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    session = InMemorySessionStore();
    auth = AuthController(database: db, sessionStore: session);
  });

  tearDown(() => db.close());

  test('signUp creates user and session', () async {
    expect(
      await auth.signUp('Ada Lovelace', '  User@Test.DEV ', 'password12'),
      isNull,
    );
    expect(auth.isSignedIn, isTrue);
    expect(auth.userId, isNotNull);
    expect(await session.readUserId(), auth.userId.toString());
    final row = await db.userByEmail('user@test.dev');
    expect(row, isNotNull);
    expect(row!.name, 'Ada Lovelace');
    expect(row.passwordHash, hashPassword('password12', row.salt));
  });

  test('signUp rejects short password', () async {
    expect(await auth.signUp('Bob', 'a@b.com', 'short'), isNotEmpty);
    expect(auth.isSignedIn, isFalse);
  });

  test('signUp rejects empty name', () async {
    expect(await auth.signUp('  ', 'a@b.com', 'longenough'), isNotEmpty);
    expect(auth.isSignedIn, isFalse);
  });

  test('signIn succeeds after signUp', () async {
    await auth.signUp('Who', 'who@test.dev', 'longpassword1');
    await auth.signOut();
    expect(auth.isSignedIn, isFalse);
    expect(await auth.signIn('who@test.dev', 'longpassword1'), isNull);
    expect(auth.isSignedIn, isTrue);
  });

  test('signIn rejects wrong password', () async {
    await auth.signUp('Who', 'who@test.dev', 'longpassword1');
    await auth.signOut();
    expect(await auth.signIn('who@test.dev', 'wrongpassword'), isNotEmpty);
    expect(auth.isSignedIn, isFalse);
  });

  test('loadSession restores user id', () async {
    await auth.signUp('Persist', 'persist@test.dev', 'longpassword1');
    final id = auth.userId;
    final auth2 = AuthController(database: db, sessionStore: session);
    await auth2.loadSession();
    expect(auth2.userId, id);
  });
}
