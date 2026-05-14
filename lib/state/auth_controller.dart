import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../services/crypto_utils.dart';
import 'session_store.dart';

class AuthController extends ChangeNotifier {
  AuthController({required AppDatabase database, SessionStore? sessionStore})
    : _db = database,
      _session = sessionStore ?? SecureSessionStore();

  final AppDatabase _db;
  final SessionStore _session;

  int? _userId;
  int? get userId => _userId;
  bool get isSignedIn => _userId != null;

  Future<void> loadSession() async {
    try {
      final raw = await _session.readUserId();
      final parsed = int.tryParse(raw ?? '');
      _userId = parsed;
    } catch (e, st) {
      assert(() {
        debugPrint('loadSession failed: $e\n$st');
        return true;
      }());
      _userId = null;
    }
    notifyListeners();
  }

  Future<String?> signUp(String name, String email, String password) async {
    final displayName = name.trim();
    if (displayName.isEmpty) return 'Enter your name.';
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return 'Enter an email address.';
    if (password.length < 8) {
      return 'Use at least 8 characters for the password.';
    }
    try {
      final existing = await _db.userByEmail(normalized);
      if (existing != null) return 'An account already exists for that email.';
      final salt = randomSalt();
      final hash = hashPassword(password, salt);
      final id = await _db.createUser(
        email: normalized,
        passwordHash: hash,
        salt: salt,
        name: displayName,
      );
      await _session.writeUserId(id.toString());
      _userId = id;
      notifyListeners();
      return null;
    } catch (e, st) {
      assert(() {
        debugPrint('signUp failed: $e\n$st');
        return true;
      }());
      return 'Could not create your account. Please try again.\n$e\n$st';
    }
  }

  Future<String?> signIn(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    try {
      final user = await _db.userByEmail(normalized);
      if (user == null) return 'No account found for that email.';
      final hash = hashPassword(password, user.salt);
      if (hash != user.passwordHash) return 'Incorrect password.';
      await _session.writeUserId(user.id.toString());
      _userId = user.id;
      notifyListeners();
      return null;
    } catch (e, st) {
      assert(() {
        debugPrint('signIn failed: $e\n$st');
        return true;
      }());
      return 'Could not sign in. Please try again.\n$e\n$st';
    }
  }

  Future<void> signOut() async {
    try {
      await _session.clearUserId();
    } catch (e, st) {
      assert(() {
        debugPrint('signOut failed: $e\n$st');
        return true;
      }());
    }
    _userId = null;
    notifyListeners();
  }
}
