import 'package:flutter_test/flutter_test.dart';

import 'package:dhis_todo/services/crypto_utils.dart';

void main() {
  group('hashPassword', () {
    test('is stable for same password and salt', () {
      const salt = 'fixed-salt';
      const password = 'hunter42';
      expect(hashPassword(password, salt), hashPassword(password, salt));
    });

    test('changes when salt changes', () {
      const password = 'same';
      expect(
        hashPassword(password, 'salt-a'),
        isNot(equals(hashPassword(password, 'salt-b'))),
      );
    });

    test('changes when password changes', () {
      const salt = 'salt';
      expect(
        hashPassword('a', salt),
        isNot(equals(hashPassword('b', salt))),
      );
    });
  });

  group('randomSalt', () {
    test('produces different values', () {
      expect(randomSalt(), isNot(equals(randomSalt())));
    });
  });
}
