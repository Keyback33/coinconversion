import 'dart:convert';

import 'package:coinconversion/app.dart';
import 'package:coinconversion/features/rates/exchange_rate_source.dart';
import 'package:coinconversion/features/rates/rate_snapshot.dart';
import 'package:coinconversion/features/rates/rates_cache.dart';
import 'package:coinconversion/providers.dart';
import 'package:coinconversion/shared/app_failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('convierte, invierte, copia y abre ajustes', (tester) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    final now = DateTime.now().toUtc();
    final source = _FixtureSource(
      RateSnapshot(
        baseCode: 'USD',
        rates: const {
          'USD': 1,
          'ARS': 1450,
          'PEN': 3.745,
          'EUR': 0.92,
          'BRL': 5.1,
          'CLP': 930,
          'UYU': 39.2,
        },
        providerId: 'exchange_rate_api',
        quotedAtUtc: now.subtract(const Duration(minutes: 10)),
        fetchedAtUtc: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          primaryRateSourceProvider.overrideWithValue(source),
          fallbackRateSourceProvider.overrideWithValue(source),
        ],
        child: const CoinConversionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CoinConversion'), findsOneWidget);
    expect(find.textContaining('Fuente: ExchangeRate-API'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('amount-field')));
    await tester.enterText(find.byKey(const Key('amount-field')), '100');
    await tester.pump();
    expect(find.textContaining('374,50'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Invertir monedas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Invertir monedas'));
    await tester.pump();
    expect(find.textContaining('26,70'), findsOneWidget);

    final visibleResult = tester
        .widget<Text>(find.byKey(const Key('conversion-result')))
        .data;
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.copy));
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump(const Duration(milliseconds: 500));
    expect(copiedText, visibleResult);

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Proveedor principal'), findsOneWidget);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  testWidgets('primera ejecución sin red mantiene configuración disponible', (
    tester,
  ) async {
    const failing = _ThrowingSource();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          primaryRateSourceProvider.overrideWithValue(failing),
          fallbackRateSourceProvider.overrideWithValue(failing),
        ],
        child: const CoinConversionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay cotizaciones'), findsOneWidget);
    expect(
      find.textContaining('Conectate una vez para descargarlas'),
      findsOneWidget,
    );
    expect(find.text('Agregar moneda'), findsOneWidget);
    expect(find.byTooltip('Ajustes'), findsOneWidget);
  });

  testWidgets('cache sigue visible si ambos providers fallan', (tester) async {
    final cached = _snapshot(
      'exchange_rate_api',
      DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          RatesCache.key: jsonEncode({
            'schemaVersion': RatesCache.schemaVersion,
            'snapshot': cached.toJson(),
          }),
        });
    const failing = _ThrowingSource();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          primaryRateSourceProvider.overrideWithValue(failing),
          fallbackRateSourceProvider.overrideWithValue(failing),
        ],
        child: const CoinConversionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Datos guardados'), findsOneWidget);
    expect(
      find.text('No se pudo actualizar; usando datos guardados.'),
      findsOneWidget,
    );
    expect(find.textContaining('Fuente: ExchangeRate-API'), findsWidgets);
  });

  testWidgets('fallback actualiza tasas, provider y fechas juntos', (
    tester,
  ) async {
    final now = DateTime.now().toUtc();
    final cached = _snapshot(
      'exchange_rate_api',
      now.subtract(const Duration(days: 1)),
    );
    final fallback = _snapshot(
      'open_exchange_rates',
      now.subtract(const Duration(minutes: 5)),
    );
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          RatesCache.key: jsonEncode({
            'schemaVersion': RatesCache.schemaVersion,
            'snapshot': cached.toJson(),
          }),
        });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          primaryRateSourceProvider.overrideWithValue(_FixtureSource(cached)),
          fallbackRateSourceProvider.overrideWithValue(
            _FixtureSource(fallback),
          ),
        ],
        child: const CoinConversionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Fuente: Open Exchange Rates (alternativa)'),
      findsWidgets,
    );
    expect(find.text('Datos guardados'), findsNothing);
    expect(find.textContaining('Extraído:'), findsWidgets);
  });
}

RateSnapshot _snapshot(String providerId, DateTime quotedAtUtc) {
  return RateSnapshot(
    baseCode: 'USD',
    rates: const {
      'USD': 1,
      'ARS': 1450,
      'PEN': 3.745,
      'EUR': 0.92,
      'BRL': 5.1,
      'CLP': 930,
      'UYU': 39.2,
    },
    providerId: providerId,
    quotedAtUtc: quotedAtUtc,
    fetchedAtUtc: quotedAtUtc.add(const Duration(minutes: 1)),
  );
}

class _FixtureSource implements ExchangeRateSource {
  _FixtureSource(this.snapshot);

  final RateSnapshot snapshot;

  @override
  String get providerId => snapshot.providerId;

  @override
  Uri get attributionUri => Uri.https('example.test');

  @override
  Future<RateSnapshot> fetchLatest() async => snapshot;
}

class _ThrowingSource implements ExchangeRateSource {
  const _ThrowingSource();

  @override
  String get providerId => 'fixture_failure';

  @override
  Uri get attributionUri => Uri.https('example.test');

  @override
  Future<RateSnapshot> fetchLatest() async =>
      throw const AppFailure(AppFailureKind.transport);
}
