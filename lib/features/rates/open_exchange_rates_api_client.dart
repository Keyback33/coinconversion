import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../shared/app_failure.dart';
import 'exchange_rate_source.dart';
import 'rate_snapshot.dart';

class OpenExchangeRatesApiClient implements ExchangeRateSource {
  OpenExchangeRatesApiClient({
    required http.Client client,
    required String appId,
    DateTime Function()? nowUtc,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client,
       _appId = appId.trim(),
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  static const _maxBodyBytes = 1024 * 1024;

  final http.Client _client;
  final String _appId;
  final DateTime Function() _nowUtc;
  final Duration timeout;

  @override
  String get providerId => 'open_exchange_rates';

  @override
  Uri get attributionUri => Uri.https('openexchangerates.org');

  @override
  Future<RateSnapshot> fetchLatest() async {
    if (_appId.isEmpty) {
      throw const AppFailure(AppFailureKind.missingConfiguration);
    }

    final uri = Uri.https('openexchangerates.org', '/api/latest.json', {
      'app_id': _appId,
    });
    final body = await _get(uri);
    try {
      final json = jsonDecode(utf8.decode(body));
      if (json is! Map<String, dynamic> || json['error'] == true) {
        throw const AppFailure(AppFailureKind.invalidResponse);
      }

      return RateSnapshot(
        baseCode: _requiredString(json, 'base'),
        rates: _parseRates(json['rates']),
        providerId: providerId,
        quotedAtUtc: _unixSeconds(json['timestamp']),
        fetchedAtUtc: _nowUtc(),
      );
    } on AppFailure {
      rethrow;
    } on Object {
      throw const AppFailure(AppFailureKind.invalidResponse);
    }
  }

  Future<Uint8List> _get(Uri uri) async {
    final abort = Completer<void>();
    final timeoutFailure = Completer<http.StreamedResponse>();
    final timer = Timer(timeout, () {
      if (!abort.isCompleted) {
        abort.complete();
      }
      timeoutFailure.completeError(const AppFailure(AppFailureKind.timeout));
    });

    try {
      final request = http.AbortableRequest(
        'GET',
        uri,
        abortTrigger: abort.future,
      );
      final response = await Future.any([
        _client.send(request),
        timeoutFailure.future,
      ]);
      _validateStatus(response.statusCode, response.headers);

      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.stream) {
        if (bytes.length + chunk.length > _maxBodyBytes) {
          if (!abort.isCompleted) {
            abort.complete();
          }
          throw const AppFailure(AppFailureKind.invalidResponse);
        }
        bytes.add(chunk);
      }
      return bytes.takeBytes();
    } on AppFailure {
      rethrow;
    } on http.ClientException {
      throw const AppFailure(AppFailureKind.transport);
    } on Object {
      throw const AppFailure(AppFailureKind.transport);
    } finally {
      timer.cancel();
    }
  }

  void _validateStatus(int statusCode, Map<String, String> headers) {
    if (statusCode == 200) {
      return;
    }
    if (statusCode == 401 || statusCode == 403) {
      throw AppFailure(AppFailureKind.authentication, statusCode: statusCode);
    }
    if (statusCode == 429) {
      throw AppFailure(
        AppFailureKind.rateLimited,
        statusCode: statusCode,
        retryAfter: _retryAfter(headers),
      );
    }
    if (statusCode >= 500) {
      throw AppFailure(
        AppFailureKind.serviceUnavailable,
        statusCode: statusCode,
      );
    }
    throw AppFailure(AppFailureKind.invalidResponse, statusCode: statusCode);
  }

  Duration? _retryAfter(Map<String, String> headers) {
    final value = headers['retry-after'];
    final seconds = int.tryParse(value ?? '');
    if (seconds != null && seconds >= 0) {
      return Duration(seconds: seconds);
    }
    try {
      final date = HttpDate.parse(value!);
      final duration = date.difference(_nowUtc());
      return duration.isNegative ? Duration.zero : duration;
    } on Object {
      return null;
    }
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw const AppFailure(AppFailureKind.invalidResponse);
  }
  return value;
}

Map<String, double> _parseRates(Object? value) {
  if (value is! Map<String, dynamic> || value.isEmpty) {
    throw const AppFailure(AppFailureKind.invalidResponse);
  }
  final rates = <String, double>{};
  for (final entry in value.entries) {
    final rate = entry.value;
    if (rate is! num || !rate.isFinite || rate <= 0) {
      throw const AppFailure(AppFailureKind.invalidResponse);
    }
    rates[entry.key] = rate.toDouble();
  }
  return rates;
}

DateTime _unixSeconds(Object? value) {
  if (value is! int || value <= 0) {
    throw const AppFailure(AppFailureKind.invalidResponse);
  }
  return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
}
