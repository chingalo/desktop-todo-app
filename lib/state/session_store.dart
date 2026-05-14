import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the signed-in user id between launches.
abstract class SessionStore {
  Future<String?> readUserId();

  Future<void> writeUserId(String id);

  Future<void> clearUserId();
}

/// Backed by the platform secure store (Keychain on macOS).
class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'program_pilot_user_id';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readUserId() => _storage.read(key: _key);

  @override
  Future<void> writeUserId(String id) => _storage.write(key: _key, value: id);

  @override
  Future<void> clearUserId() => _storage.delete(key: _key);
}
