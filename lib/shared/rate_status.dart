import 'package:intl/intl.dart';

import '../features/rates/rate_snapshot.dart';

abstract final class RateStatus {
  static const staleAfter = Duration(hours: 48);

  static String providerName(String providerId) {
    return switch (providerId) {
      'exchange_rate_api' => 'ExchangeRate-API',
      'open_exchange_rates' => 'Open Exchange Rates',
      _ => providerId,
    };
  }

  static Uri providerUri(String providerId) {
    return switch (providerId) {
      'open_exchange_rates' => Uri.https('openexchangerates.org'),
      _ => Uri.https('www.exchangerate-api.com'),
    };
  }

  static bool isAlternative(String providerId) =>
      providerId == 'open_exchange_rates';

  static bool isStale(RateSnapshot snapshot, DateTime nowUtc) {
    final age = nowUtc.toUtc().difference(snapshot.quotedAtUtc);
    return !age.isNegative && age > staleAfter;
  }

  static bool isFromFuture(RateSnapshot snapshot, DateTime nowUtc) => snapshot
      .quotedAtUtc
      .isAfter(nowUtc.toUtc().add(const Duration(minutes: 5)));

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
