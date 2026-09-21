import 'dart:async';
import 'dart:io';

import 'package:coinconversion/features/rates/exchange_rate_api_client.dart';
import 'package:coinconversion/shared/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('adapta una respuesta exitosa a snapshot USD', () async {
    final body = File(
      'test/fixtures/exchange_rate_api_success.json',
    ).readAsStringSync();
    final client = ExchangeRateApiClient(
      client: MockClient((request) async {
        expect(request.url.toString(), 'https://open.er-api.com/v6/latest/USD');
        return http.Response(body, 200);
      }),
      nowUtc: () => DateTime.utc(2026, 9, 20, 14, 30),
    );

    final snapshot = await client.fetchLatest();

    expect(snapshot.baseCode, 'USD');
    expect(snapshot.providerId, 'exchange_rate_api');
    expect(snapshot.rates['PEN'], 3.745);
    expect(snapshot.fetchedAtUtc, DateTime.utc(2026, 9, 20, 14, 30));
    expect(snapshot.nextUpdateAtUtc, isNotNull);
  });

  test('clasifica 429 y no interpreta el body', () async {
    final client = ExchangeRateApiClient(
      client: MockClient((request) async => http.Response('limit', 429)),
    );

    await expectLater(
      client.fetchLatest(),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.kind,
          'kind',
          AppFailureKind.rateLimited,
        ),
      ),
    );
  });

  test('rechaza contrato lógico fallido y tasas string', () async {
    final logicalFailure = ExchangeRateApiClient(
      client: MockClient(
        (request) async => http.Response('{"result":"error"}', 200),
      ),
    );
    final stringRate = ExchangeRateApiClient(
      client: MockClient(
        (request) async => http.Response(
          '{"result":"success","base_code":"USD",'
          '"time_last_update_unix":1789905600,'
          '"rates":{"USD":1,"ARS":"1450"}}',
          200,
        ),
      ),
    );

    await _expectInvalid(logicalFailure.fetchLatest());
    await _expectInvalid(stringRate.fetchLatest());
  });

  test('cancela por timeout total', () async {
    final pending = Completer<http.Response>();
    final client = ExchangeRateApiClient(
      client: MockClient((request) => pending.future),
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

Future<void> _expectInvalid(Future<Object?> future) {
  return expectLater(
    future,
    throwsA(
      isA<AppFailure>().having(
        (failure) => failure.kind,
        'kind',
        AppFailureKind.invalidResponse,
      ),
    ),
  );
}
