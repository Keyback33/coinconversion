import 'package:intl/intl.dart';

import '../features/rates/rate_snapshot.dart';

abstract final class RateStatus {
  static const staleAfter = Duration(hours: 48);

  static String providerName(String providerId) {
    return switch (providerId) {
      'exchange_rate_api' => 'ExchangeRate-API',
      'open_exchange_rates' => 'Open Exchange Rates',
      'frankfurter' => 'Frankfurter',
      _ => providerId,
    };
  }

  static Uri providerUri(String providerId) {
    return switch (providerId) {
      'open_exchange_rates' => Uri.https('openexchangerates.org'),
      'frankfurter' => Uri.https('frankfurter.dev'),
      _ => Uri.https('www.exchangerate-api.com'),
    };
  }

  static bool isAlternative(String providerId) =>
      providerId == 'open_exchange_rates' || providerId == 'frankfurter';

  static bool isStale(RateSnapshot snapshot, DateTime nowUtc) {
    final date = snapshot.hasDailyDates
        ? snapshot.quotedAtUtc.add(const Duration(days: 1))
        : snapshot.quotedAtUtc;
    final age = nowUtc.toUtc().difference(date);
    return !age.isNegative && age > staleAfter;
  }

  static bool isFromFuture(RateSnapshot snapshot, DateTime nowUtc) => snapshot
      .quotedAtUtc
      .isAfter(nowUtc.toUtc().add(const Duration(minutes: 5)));

  static String quotedDate(RateSnapshot snapshot, {String? code}) {
    final date = code == null
        ? snapshot.quotedAtUtc
        : snapshot.quotedAtFor(code);
    if (snapshot.hasDailyDates) {
      return DateFormat('dd/MM/yyyy', 'es_AR').format(date);
    }
    return localDate(date);
  }

  static String localDate(DateTime utc) {
    final local = utc.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final absoluteMinutes = offset.inMinutes.abs();
    final hours = (absoluteMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (absoluteMinutes % 60).toString().padLeft(2, '0');
    return '${DateFormat('dd/MM/yyyy HH:mm', 'es_AR').format(local)} '
        '(UTC$sign$hours:$minutes)';
  }
}
