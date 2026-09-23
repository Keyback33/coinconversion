import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../shared/app_failure.dart';
import '../currencies/currency_catalog.dart';
import 'exchange_rate_source.dart';
import 'rate_snapshot.dart';

class FrankfurterApiClient implements ExchangeRateSource {
  FrankfurterApiClient({
    required http.Client client,
    DateTime Function()? nowUtc,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client,
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  static const _maxBodyBytes = 1024 * 1024;
  final http.Client _client;
  final DateTime Function() _nowUtc;
  final Duration timeout;

  @override
  String get providerId => 'frankfurter';

  @override
  Uri get attributionUri => Uri.https('frankfurter.dev');

  @override
  Future<RateSnapshot> fetchLatest() async {
    final codes = CurrencyCatalog.currencies.map((currency) => currency.code);
    final uri = Uri.https('api.frankfurter.dev', '/v2/rates', {
      'base': 'USD',
      'quotes': codes.join(','),
    });
    final body = await _get(uri);
    try {
      final rows = jsonDecode(utf8.decode(body));
      if (rows is! List || rows.isEmpty) {
        throw const FormatException('rates');
      }
      final expected = codes.toSet();
      final rates = <String, double>{};
      final dates = <String, DateTime>{};
      for (final row in rows) {
        if (row is! Map<String, dynamic> || row['base'] != 'USD') {
          throw const FormatException('base');
        }
        final quote = row['quote'];
        final rate = row['rate'];
        final dateText = row['date'];
        if (quote is! String ||
            !expected.contains(quote) ||
            rates.containsKey(quote) ||
            rate is! num ||
            !rate.isFinite ||
            rate <= 0 ||
            dateText is! String ||
            !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateText)) {
          throw const FormatException('rate');
        }
        final date = DateTime.tryParse('${dateText}T00:00:00Z');
        if (date == null ||
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}' !=
                dateText) {
          throw const FormatException('date');
        }
        rates[quote] = rate.toDouble();
        dates[quote] = date;
      }
      if (rates.keys.toSet().difference(expected).isNotEmpty ||
          expected.difference(rates.keys.toSet()).isNotEmpty ||
          rates['USD'] != 1) {
        throw const FormatException('incomplete rates');
      }
      final relevantDates = dates.entries
          .where((entry) => entry.key != 'ARS' && entry.key != 'USD')
          .map((entry) => entry.value);
      final oldest = relevantDates.reduce(
        (previous, next) => next.isBefore(previous) ? next : previous,
      );
      return RateSnapshot(
        baseCode: 'USD',
        rates: rates,
        providerId: providerId,
        quotedAtUtc: oldest,
        fetchedAtUtc: _nowUtc(),
        quotedDatesUtc: dates,
      );
    } on AppFailure {
      rethrow;
    } on Object {
      throw const AppFailure(AppFailureKind.invalidResponse);
    }
  }

  Future<Uint8List> _get(Uri uri) async {
    final abort = Completer<void>();
    try {
      return await _sendAndRead(uri, abort).timeout(timeout);
    } on TimeoutException {
      if (!abort.isCompleted) abort.complete();
      throw const AppFailure(AppFailureKind.timeout);
    } on AppFailure {
      rethrow;
    } on http.ClientException {
      throw const AppFailure(AppFailureKind.transport);
    } on Object {
      throw const AppFailure(AppFailureKind.transport);
    }
  }

  Future<Uint8List> _sendAndRead(Uri uri, Completer<void> abort) async {
    final response = await _client.send(
      http.AbortableRequest('GET', uri, abortTrigger: abort.future),
    );
    if (response.statusCode != 200) {
      if (response.statusCode == 429) {
        throw AppFailure(
          AppFailureKind.rateLimited,
          statusCode: 429,
          retryAfter: _retryAfter(response.headers),
        );
      }
      throw AppFailure(
        response.statusCode >= 500
            ? AppFailureKind.serviceUnavailable
            : AppFailureKind.invalidResponse,
        statusCode: response.statusCode,
      );
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > _maxBodyBytes) {
        if (!abort.isCompleted) abort.complete();
        throw const AppFailure(AppFailureKind.invalidResponse);
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  Duration? _retryAfter(Map<String, String> headers) {
    final value = headers['retry-after'];
    final seconds = int.tryParse(value ?? '');
    if (seconds != null && seconds >= 0) return Duration(seconds: seconds);
    try {
      final duration = HttpDate.parse(value!).difference(_nowUtc());
      return duration.isNegative ? Duration.zero : duration;
    } on Object {
      return null;
    }
  }
}
