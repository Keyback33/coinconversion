import 'dart:convert';

import 'package:coinconversion/features/rates/argentina_datos_mep_client.dart';
import 'package:coinconversion/features/rates/dolar_api_client.dart';
import 'package:coinconversion/features/rates/mep_quote.dart';
import 'package:coinconversion/shared/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final now = DateTime.utc(2026, 9, 22, 21);

  test('DolarAPI valida mercado y conserva timestamp', () async {
    final client = DolarApiClient(
      client: MockClient((request) async {
        expect(request.url.toString(), 'https://dolarapi.com/v1/dolares/bolsa');
        return http.Response(
          jsonEncode({
            'moneda': 'USD',
            'casa': 'bolsa',
            'venta': 1200,
            'fechaActualizacion': '2026-09-22T20:00:00Z',
          }),
          200,
        );
      }),
      nowUtc: () => now,
    );
    final quote = await client.fetchLatest();
    expect(quote.sellArsPerUsd, 1200);
    expect(quote.buyArsPerUsd, isNull);
    expect(quote.quotedDate, '2026-09-22');
    expect(quote.precision, MepTimePrecision.instant);
  });

  test('DolarAPI rechaza venta ausente y fecha futura', () async {
    for (final body in [
      {
        'moneda': 'USD',
        'casa': 'bolsa',
        'fechaActualizacion': '2026-09-22T20:00:00Z',
      },
      {
        'moneda': 'USD',
        'casa': 'bolsa',
        'venta': 1200,
        'fechaActualizacion': '2026-09-22T21:06:00Z',
      },
    ]) {
      final client = DolarApiClient(
        client: MockClient((_) async => http.Response(jsonEncode(body), 200)),
        nowUtc: () => now,
      );
      expect(
        client.fetchLatest(),
        throwsA(
          isA<AppFailure>().having(
            (error) => error.kind,
            'kind',
            AppFailureKind.invalidResponse,
          ),
        ),
      );
    }
  });

  test('histórico elige fecha máxima sin depender del orden', () async {
    final client = ArgentinaDatosMepClient(
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.argentinadatos.com/v1/cotizaciones/dolares/bolsa',
        );
        return http.Response(
          jsonEncode([
            {'casa': 'bolsa', 'venta': 1190, 'fecha': '2026-09-21'},
            {'casa': 'blue', 'venta': 2000, 'fecha': '2026-09-22'},
            {'casa': 'bolsa', 'venta': 1200.5, 'fecha': '2026-09-22'},
            {'casa': 'bolsa', 'venta': 1195, 'fecha': '2026-09-20'},
          ]),
          200,
        );
      }),
      nowUtc: () => now,
    );
    final quote = await client.fetchLatest();
    expect(quote.sellArsPerUsd, 1200.5);
    expect(quote.quotedDate, '2026-09-22');
    expect(quote.quotedAtUtc, isNull);
  });

  test('histórico contradictorio para el día máximo se rechaza', () async {
    final client = ArgentinaDatosMepClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {'casa': 'bolsa', 'venta': 1200, 'fecha': '2026-09-22'},
            {'casa': 'bolsa', 'venta': 1201, 'fecha': '2026-09-22'},
          ]),
          200,
        ),
      ),
      nowUtc: () => now,
    );
    expect(
      client.fetchLatest(),
      throwsA(
        isA<AppFailure>().having(
          (error) => error.kind,
          'kind',
          AppFailureKind.invalidResponse,
        ),
      ),
    );
  });

  test('HTTP 429 respeta Retry-After', () async {
    final client = DolarApiClient(
      client: MockClient(
        (_) async => http.Response('', 429, headers: {'retry-after': '45'}),
      ),
      nowUtc: () => now,
    );
    expect(
      client.fetchLatest(),
      throwsA(
        isA<AppFailure>().having(
          (error) => error.retryAfter,
          'retryAfter',
          const Duration(seconds: 45),
        ),
      ),
    );
  });

  test('respuesta mayor a 1 MiB se rechaza sin truncar', () async {
    final client = DolarApiClient(
      client: MockClient(
        (_) async => http.Response('x' * (1024 * 1024 + 1), 200),
      ),
      nowUtc: () => now,
    );
    expect(
      client.fetchLatest(),
      throwsA(
        isA<AppFailure>().having(
          (error) => error.kind,
          'kind',
          AppFailureKind.invalidResponse,
        ),
      ),
    );
  });

  test('timeout de headers se informa y cancela la consulta', () async {
    final client = DolarApiClient(
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return http.Response('{}', 200);
      }),
      nowUtc: () => now,
      timeout: const Duration(milliseconds: 1),
    );
    expect(
      client.fetchLatest(),
      throwsA(
        isA<AppFailure>().having(
          (error) => error.kind,
          'kind',
          AppFailureKind.timeout,
        ),
      ),
    );
  });
}
