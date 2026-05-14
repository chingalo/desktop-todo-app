import 'dart:convert';

import 'package:http/http.dart' as http;

class DhisProgramSummary {
  const DhisProgramSummary({
    required this.id,
    required this.displayName,
    this.shortName,
  });

  final String id;
  final String displayName;
  final String? shortName;
}

/// Fetches DHIS2 metadata with HTTP Basic authentication.
class DhisClient {
  DhisClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const defaultProgramsUrl =
      'https://play.im.dhis2.org/stable-2-42-4-1/api/programs.json?paging=false';
  static const defaultUsername = 'system';
  static const defaultPassword = 'System123';

  Future<List<DhisProgramSummary>> fetchPrograms({
    String? programsUrl,
    String? username,
    String? password,
  }) async {
    final uri = Uri.parse(programsUrl ?? defaultProgramsUrl);
    final user = username ?? defaultUsername;
    final pass = password ?? defaultPassword;
    final basic = base64Encode(utf8.encode('$user:$pass'));
    final response = await _http.get(
      uri,
      headers: {'Authorization': 'Basic $basic', 'Accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DhisHttpException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object from DHIS2');
    }
    final raw = decoded['programs'];
    if (raw is! List<dynamic>) {
      return const [];
    }
    return raw
        .map((e) {
          final m = e as Map<String, dynamic>;
          final id = m['id']?.toString() ?? '';
          final name = (m['displayName'] ?? m['name'] ?? id).toString();
          final short = (m['shortName'] ?? '').toString();
          return DhisProgramSummary(
            id: id,
            displayName: name,
            shortName: short,
          );
        })
        .where((p) => p.id.isNotEmpty)
        .toList();
  }
}

class DhisHttpException implements Exception {
  DhisHttpException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'DHIS2 request failed ($statusCode)';
}
