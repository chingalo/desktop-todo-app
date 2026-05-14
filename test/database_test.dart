import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dhis_todo/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('user and todo CRUD', () async {
    final userId = await db.createUser(
      email: 'user@test.dev',
      passwordHash: 'hash',
      salt: 'salt',
    );

    final tid = await db.insertTodo(
      userId: userId,
      title: 'Buy milk',
      description: '2%',
      dhisProgramId: 'prog-1',
    );

    var list = await db.watchTodosForUser(userId).first;
    expect(list, hasLength(1));
    expect(list.single.title, 'Buy milk');
    expect(list.single.completed, false);

    final row = list.single;
    await db.updateTodo(row.copyWith(completed: true, updatedAt: DateTime.now()));
    list = await db.watchTodosForUser(userId).first;
    expect(list.single.completed, true);

    await db.deleteTodo(tid);
    list = await db.watchTodosForUser(userId).first;
    expect(list, isEmpty);
  });

  test('replaceCachedPrograms stores rows', () async {
    await db.replaceCachedPrograms([
      CachedProgramsCompanion.insert(id: 'a', displayName: 'Alpha'),
      CachedProgramsCompanion.insert(
        id: 'b',
        displayName: 'Beta',
        shortName: const Value('B'),
      ),
    ]);
    final cached = await db.watchCachedPrograms().first;
    expect(cached, hasLength(2));
    expect(cached.map((e) => e.id).toList()..sort(), ['a', 'b']);
  });
}
