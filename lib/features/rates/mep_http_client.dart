import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../shared/app_failure.dart';

class MepHttpClient {
  const MepHttpClient(
    this.client,
    this.nowUtc, {
    this.timeout = const Duration(seconds: 10),
  });

  final http.Client client;
  final DateTime Function() nowUtc;
  final Duration timeout;

  Future<Object?> getJson(Uri uri) async {
    final abort = Completer<void>();
    final request = http.AbortableRequest(
      'GET',
      uri,
      abortTrigger: abort.future,
    );
    final elapsed = Stopwatch()..start();
    try {
      final response = await client.send(request).timeout(timeout);
      if (response.statusCode != 200) {
        if (response.statusCode == 429) {
          throw AppFailure(
            AppFailureKind.rateLimited,
            statusCode: 429,
            retryAfter: _retryAfter(response.headers),
          );
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw AppFailure(
            AppFailureKind.authentication,
            statusCode: response.statusCode,
          );
        }
        if (response.statusCode >= 500) {
          throw AppFailure(
            AppFailureKind.serviceUnavailable,
            statusCode: response.statusCode,
          );
        }
        throw AppFailure(
          AppFailureKind.invalidResponse,
          statusCode: response.statusCode,
        );
      }
      Future<List<int>> readBody() async {
        final bytes = <int>[];
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > 1024 * 1024) {
            if (!abort.isCompleted) abort.complete();
            throw const AppFailure(AppFailureKind.invalidResponse);
          }
          bytes.addAll(chunk);
        }
        return bytes;
      }

      final remaining = timeout - elapsed.elapsed;
      final bytes = await readBody().timeout(
        remaining.isNegative ? Duration.zero : remaining,
      );
      return jsonDecode(utf8.decode(bytes));
    } on TimeoutException {
      if (!abort.isCompleted) abort.complete();
      throw const AppFailure(AppFailureKind.timeout);
    } on AppFailure {
      rethrow;
    } on http.ClientException {
      if (abort.isCompleted) throw const AppFailure(AppFailureKind.timeout);
      throw const AppFailure(AppFailureKind.transport);
    } on FormatException {
      throw const AppFailure(AppFailureKind.invalidResponse);
    } on Object {
      if (abort.isCompleted) throw const AppFailure(AppFailureKind.timeout);
      throw const AppFailure(AppFailureKind.transport);
    } finally {
      elapsed.stop();
    }
  }

  Duration? _retryAfter(Map<String, String> headers) {
    final value = headers['retry-after'];
    final seconds = int.tryParse(value ?? '');
    if (seconds != null && seconds >= 0) return Duration(seconds: seconds);
    try {
      final duration = HttpDate.parse(value!).difference(nowUtc().toUtc());
      return duration.isNegative ? Duration.zero : duration;
    } on Object {
      return null;
    }
  }
}
