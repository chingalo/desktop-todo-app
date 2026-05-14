import 'package:dhis_todo/state/session_store.dart';

/// In-memory session for unit/widget tests (no platform secure storage).
class InMemorySessionStore implements SessionStore {
  String? _userId;

  @override
  Future<void> clearUserId() async {
    _userId = null;
  }

  @override
  Future<String?> readUserId() async => _userId;

  @override
  Future<void> writeUserId(String id) async {
    _userId = id;
  }
}
