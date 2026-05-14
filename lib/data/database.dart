import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get passwordHash => text()();
  TextColumn get salt => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 400)();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Last fetched DHIS2 programs for offline reference.
class CachedPrograms extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get shortName => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@DriftDatabase(tables: [Users, Todos, CachedPrograms])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Increment [schemaVersion] whenever tables/columns change. Run steps in
      // ascending order so installs that skip app versions still migrate.
      for (var v = from; v < to; v++) {
        switch (v) {
          case 1:
            // Example when moving to schemaVersion 2:
            // await m.addColumn(todos, todos.someNewColumn);
            break;
        }
      }
    },
  );

  Future<int> createUser({
    required String email,
    required String passwordHash,
    required String salt,
    String name = '',
  }) {
    return into(users).insert(
      UsersCompanion.insert(
        email: email,
        passwordHash: passwordHash,
        salt: salt,
        name: Value(name),
      ),
    );
  }

  Future<User?> userByEmail(String email) {
    return (select(
      users,
    )..where((u) => u.email.equals(email))).getSingleOrNull();
  }

  Stream<List<Todo>> watchTodosForUser(int userId) {
    return (select(todos)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<Todo>> todosForUser(int userId) {
    return (select(todos)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<int> insertTodo({
    required int userId,
    required String title,
    String description = '',
  }) {
    return into(todos).insert(
      TodosCompanion.insert(
        userId: userId,
        title: title,
        description: Value(description),
      ),
    );
  }

  Future<void> updateTodo(Todo row) {
    return (update(todos)..where((t) => t.id.equals(row.id))).write(
      TodosCompanion(
        title: Value(row.title),
        description: Value(row.description),
        completed: Value(row.completed),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteTodo(int id) {
    return (delete(todos)..where((t) => t.id.equals(id))).go();
  }

  Future<void> replaceCachedPrograms(List<CachedProgramsCompanion> rows) async {
    await delete(cachedPrograms).go();
    await batch((b) {
      b.insertAll(cachedPrograms, rows);
    });
  }

  Stream<List<CachedProgram>> watchCachedPrograms() =>
      select(cachedPrograms).watch();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'program_pilot.sqlite'));
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    return NativeDatabase.createInBackground(file);
  });
}
