import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dhis_todo/services/dhis_client.dart';

void main() {
  group('DhisClient', () {
    test('sends Basic auth and parses programs', () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], startsWith('Basic '));
        final decoded = utf8.decode(
          base64Decode(request.headers['Authorization']!.split(' ').last),
        );
        expect(decoded, 'apiuser:secret');
        return http.Response(
          '{"programs":[{"id":"p1","displayName":"Program One","shortName":"P1"}]}',
          200,
        );
      });
      final dhis = DhisClient(httpClient: client);
      final list = await dhis.fetchPrograms(
        programsUrl: 'https://example.org/api/programs.json',
        username: 'apiuser',
        password: 'secret',
      );
      expect(list, hasLength(1));
      expect(list.single.id, 'p1');
      expect(list.single.displayName, 'Program One');
      expect(list.single.shortName, 'P1');
    });

    test('returns empty list when programs is not a list', () async {
      final client = MockClient(
        (_) async => http.Response('{"programs": "nope"}', 200),
      );
      final dhis = DhisClient(httpClient: client);
      expect(await dhis.fetchPrograms(programsUrl: 'https://x.test/'), isEmpty);
    });

    test('throws on non-2xx', () async {
      final client = MockClient((_) async => http.Response('err', 401));
      final dhis = DhisClient(httpClient: client);
      expect(
        () => dhis.fetchPrograms(programsUrl: 'https://x.test/'),
        throwsA(isA<DhisHttpException>()),
      );
    });

    test('throws when body is not a JSON object', () async {
      final client = MockClient((_) async => http.Response('[]', 200));
      final dhis = DhisClient(httpClient: client);
      expect(
        () => dhis.fetchPrograms(programsUrl: 'https://x.test/'),
        throwsA(isA<FormatException>()),
      );
    });

    test('skips programs with empty id', () async {
      final client = MockClient(
        (_) async => http.Response(
          '{"programs":[{"id":"","displayName":"X"},{"id":"ok","displayName":"Y"}]}',
          200,
        ),
      );
      final dhis = DhisClient(httpClient: client);
      final list = await dhis.fetchPrograms(programsUrl: 'https://x.test/');
      expect(list.map((e) => e.id), ['ok']);
    });
  });
}
