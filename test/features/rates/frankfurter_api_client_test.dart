import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coinconversion/features/rates/frankfurter_api_client.dart';
import 'package:coinconversion/shared/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final fixture = File(
    'test/fixtures/frankfurter_success.json',
  ).readAsStringSync();

  test('consulta catálogo y conserva fechas por par', () async {
    final client = FrankfurterApiClient(
      client: MockClient((request) async {
        expect(request.url.host, 'api.frankfurter.dev');
        expect(request.url.path, '/v2/rates');
        expect(request.url.queryParameters['base'], 'USD');
        expect(
          request.url.queryParameters['quotes']!.split(','),
          containsAll(['USD', 'ARS', 'PEN', 'EUR', 'BRL', 'CLP', 'UYU']),
        );
        return http.Response(fixture, 200);
      }),
      nowUtc: () => DateTime.utc(2026, 9, 23),
    );
    final snapshot = await client.fetchLatest();
    expect(snapshot.providerId, 'frankfurter');
    expect(snapshot.quotedAtUtc, DateTime.utc(2026, 9, 21));
    expect(snapshot.quotedAtFor('EUR'), DateTime.utc(2026, 9, 22));
    expect(snapshot.quotedAtFor('BRL'), DateTime.utc(2026, 9, 21));
    expect(snapshot.hasDailyDates, isTrue);
    expect(snapshot.rates['ARS'], 1450);
  });

  test('rechaza tablas incompletas, duplicadas y fechas inválidas', () async {
    final rows = jsonDecode(fixture) as List<dynamic>;
    final cases = [
      jsonEncode(rows.sublist(1)),
      jsonEncode([...rows, rows.first]),
      jsonEncode(
        rows
            .map(
              (row) => row == rows.first
                  ? {...row as Map<String, dynamic>, 'date': '2026-02-30'}
                  : row,
            )
            .toList(),
      ),
      jsonEncode(
        rows
            .map(
              (row) => row == rows.first
                  ? {...row as Map<String, dynamic>, 'rate': '5.1'}
                  : row,
            )
            .toList(),
      ),
      '{',
    ];
    for (final body in cases) {
      final client = FrankfurterApiClient(
        client: MockClient((request) async => http.Response(body, 200)),
      );
      await expectLater(
        client.fetchLatest(),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.kind,
            'kind',
            AppFailureKind.invalidResponse,
          ),
        ),
      );
    }
  });

  test('clasifica 429 con Retry-After y timeout de headers', () async {
    final limited = FrankfurterApiClient(
      client: MockClient(
        (request) async =>
            http.Response('', 429, headers: {'retry-after': '120'}),
      ),
    );
    await expectLater(
      limited.fetchLatest(),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.retryAfter,
          'retryAfter',
          const Duration(minutes: 2),
        ),
      ),
    );
    final pending = Completer<http.Response>();
    final timedOut = FrankfurterApiClient(
      client: MockClient((request) => pending.future),
      timeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      timedOut.fetchLatest(),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.kind,
          'kind',
          AppFailureKind.timeout,
        ),
      ),
    );
  });

  test('clasifica errores HTTP y transporte', () async {
    for (final status in [404, 422, 503]) {
      final client = FrankfurterApiClient(
        client: MockClient((request) async => http.Response('', status)),
      );
      await expectLater(
        client.fetchLatest(),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.kind,
            'kind',
            status == 503
                ? AppFailureKind.serviceUnavailable
                : AppFailureKind.invalidResponse,
          ),
        ),
      );
    }
    final broken = FrankfurterApiClient(
      client: MockClient(
        (request) async => throw const SocketException('offline'),
      ),
    );
    await expectLater(
      broken.fetchLatest(),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.kind,
          'kind',
          AppFailureKind.transport,
        ),
      ),
    );
  });

  test('rechaza body mayor a 1 MiB', () async {
    final client = FrankfurterApiClient(
      client: MockClient(
        (request) async => http.Response(' ' * (1024 * 1024 + 1), 200),
      ),
    );
    await expectLater(
      client.fetchLatest(),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.kind,
          'kind',
          AppFailureKind.invalidResponse,
        ),
      ),
    );
  });

  test('timeout cubre también el body sin fin', () async {
    final stream = StreamController<List<int>>();
    addTearDown(stream.close);
    final client = FrankfurterApiClient(
      client: _StreamingClient(stream.stream),
      timeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      client.fetchLatest(),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.kind,
          'kind',
          AppFailureKind.timeout,
        ),
      ),
    );
  });
}

class _StreamingClient extends http.BaseClient {
  _StreamingClient(this.body);
  final Stream<List<int>> body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(body, 200);
}
