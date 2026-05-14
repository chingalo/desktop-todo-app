import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

String randomSalt() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  return base64UrlEncode(bytes);
}

String hashPassword(String password, String salt) {
  final digest = sha256.convert(utf8.encode('$salt:$password'));
  return digest.toString();
}
