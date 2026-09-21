import 'rate_snapshot.dart';

abstract interface class ExchangeRateSource {
  String get providerId;

  Uri get attributionUri;

  Future<RateSnapshot> fetchLatest();
}
