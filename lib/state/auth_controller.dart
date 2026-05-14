import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../services/crypto_utils.dart';
import 'session_store.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AppDatabase database,
    SessionStore? sessionStore,
  }) : _db = database,
       _session = sessionStore ?? SecureSessionStore();

  final AppDatabase _db;
  final SessionStore _session;

  int? _userId;
  int? get userId => _userId;
  bool get isSignedIn => _userId != null;

  Future<void> loadSession() async {
    final raw = await _session.readUserId();
    final parsed = int.tryParse(raw ?? '');
    _userId = parsed;
    notifyListeners();
  }

  Future<String?> signUp(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return 'Enter an email address.';
    if (password.length < 8) {
      return 'Use at least 8 characters for the password.';
    }
    final existing = await _db.userByEmail(normalized);
    if (existing != null) return 'An account already exists for that email.';
    final salt = randomSalt();
    final hash = hashPassword(password, salt);
    final id = await _db.createUser(
      email: normalized,
      passwordHash: hash,
      salt: salt,
    );
    await _session.writeUserId(id.toString());
    _userId = id;
    notifyListeners();
    return null;
  }

  Future<String?> signIn(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final user = await _db.userByEmail(normalized);
    if (user == null) return 'No account found for that email.';
    final hash = hashPassword(password, user.salt);
    if (hash != user.passwordHash) return 'Incorrect password.';
    await _session.writeUserId(user.id.toString());
    _userId = user.id;
    notifyListeners();
    return null;
  }

  Future<void> signOut() async {
    await _session.clearUserId();
    _userId = null;
    notifyListeners();
  }
}
