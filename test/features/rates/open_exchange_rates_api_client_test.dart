import 'dart:io';

import 'package:coinconversion/features/rates/open_exchange_rates_api_client.dart';
import 'package:coinconversion/shared/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('envía App ID y adapta una respuesta exitosa', () async {
    final body = File(
      'test/fixtures/open_exchange_rates_success.json',
    ).readAsStringSync();
    final client = OpenExchangeRatesApiClient(
      client: MockClient((request) async {
        expect(request.url.host, 'openexchangerates.org');
        expect(request.url.path, '/api/latest.json');
        expect(request.url.queryParameters['app_id'], 'private-test-id');
        return http.Response(body, 200);
      }),
      appId: 'private-test-id',
      nowUtc: () => DateTime.utc(2026, 9, 20, 14, 35),
    );

    final snapshot = await client.fetchLatest();

    expect(snapshot.providerId, 'open_exchange_rates');
    expect(snapshot.rates['ARS'], 1451);
    expect(snapshot.nextUpdateAtUtc, isNull);
  });

  test('App ID ausente falla sin hacer requests', () async {
    var requests = 0;
    final client = OpenExchangeRatesApiClient(
      client: MockClient((request) async {
        requests++;
        return http.Response('{}', 200);
      }),
      appId: ' ',
    );

    await expectLater(
      client.fetchLatest(),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.kind,
          'kind',
          AppFailureKind.missingConfiguration,
        ),
      ),
    );
    expect(requests, 0);
  });

  test('clasifica autenticación, cuota y servicio', () async {
    for (final testCase in [
      (status: 401, kind: AppFailureKind.authentication),
      (status: 429, kind: AppFailureKind.rateLimited),
      (status: 503, kind: AppFailureKind.serviceUnavailable),
    ]) {
      final client = OpenExchangeRatesApiClient(
        client: MockClient(
          (request) async => http.Response('{}', testCase.status),
        ),
        appId: 'private-test-id',
      );

      await expectLater(
        client.fetchLatest(),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.kind,
            'kind',
            testCase.kind,
          ),
        ),
      );
    }
  });
}
