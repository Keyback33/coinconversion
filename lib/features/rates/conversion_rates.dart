import 'mep_quote.dart';
import 'rate_snapshot.dart';

class ConversionRates {
  const ConversionRates({this.snapshot, this.mep});

  final RateSnapshot? snapshot;
  final MepQuote? mep;

  bool canConvert(String from, String to) {
    if (from == to) return true;
    if (from == 'ARS' || to == 'ARS') {
      return mep != null &&
          (from == 'USD' ||
              from == 'ARS' ||
              snapshot?.rates.containsKey(from) == true) &&
          (to == 'USD' ||
              to == 'ARS' ||
              snapshot?.rates.containsKey(to) == true);
    }
    return snapshot?.rates.containsKey(from) == true &&
        snapshot?.rates.containsKey(to) == true;
  }

  String unavailableReason(String from, String to) {
    if (from == 'ARS' || to == 'ARS') {
      if (mep == null) return 'MEP no disponible';
    }
    return 'Tabla general no disponible';
  }
}
