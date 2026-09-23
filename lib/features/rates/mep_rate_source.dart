import 'mep_quote.dart';

abstract class MepRateSource {
  String get providerId;
  Future<MepQuote> fetchLatest();
}
