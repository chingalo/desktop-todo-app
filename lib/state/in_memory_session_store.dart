import 'session_store.dart';

/// In-memory session store (no Keychain / secure storage).
///
/// Use for **tests** and **integration_test** so desktop harnesses do not
/// require keychain entitlements. Production [main] uses [SecureSessionStore].
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
