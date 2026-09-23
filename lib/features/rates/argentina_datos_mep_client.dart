import 'package:http/http.dart' as http;

import '../../shared/app_failure.dart';
import 'mep_http_client.dart';
import 'mep_quote.dart';
import 'mep_rate_source.dart';

class ArgentinaDatosMepClient implements MepRateSource {
  ArgentinaDatosMepClient({
    required http.Client client,
    DateTime Function()? nowUtc,
    Duration timeout = const Duration(seconds: 10),
  }) : _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
       _http = MepHttpClient(
         client,
         nowUtc ?? (() => DateTime.now().toUtc()),
         timeout: timeout,
       );

  final DateTime Function() _nowUtc;
  final MepHttpClient _http;

  @override
  String get providerId => 'argentina_datos';

  @override
  Future<MepQuote> fetchLatest() async {
    final data = await _http.getJson(
      Uri.https('api.argentinadatos.com', '/v1/cotizaciones/dolares/bolsa'),
    );
    if (data is! List) {
      throw const AppFailure(AppFailureKind.invalidResponse);
    }
    MepQuote? selected;
    var conflicting = false;
    var discarded = 0;
    for (final row in data) {
      try {
        if (row is! Map<String, dynamic> ||
            row['casa'] != 'bolsa' ||
            (row['moneda'] != null && row['moneda'] != 'USD')) {
          discarded++;
          continue;
        }
        final rawDate = row['fecha'];
        final sell = row['venta'];
        if (rawDate is! String ||
            sell is! num ||
            !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate)) {
          discarded++;
          continue;
        }
        final parsed = DateTime.tryParse('${rawDate}T00:00:00Z');
        if (parsed == null ||
            parsed.toIso8601String().substring(0, 10) != rawDate) {
          discarded++;
          continue;
        }
        final buy = row['compra'];
        final candidate = MepQuote(
          sellArsPerUsd: sell.toDouble(),
          buyArsPerUsd: buy is num && buy.isFinite && buy > 0
              ? buy.toDouble()
              : null,
          providerId: providerId,
          quotedDate: rawDate,
          precision: MepTimePrecision.date,
          fetchedAtUtc: _nowUtc().toUtc(),
        );
        if (!candidate.isValidAt(_nowUtc())) {
          discarded++;
          continue;
        }
        final comparison = selected == null
            ? 1
            : candidate.compareFreshness(selected);
        if (comparison > 0) {
          selected = candidate;
          conflicting = false;
        } else if (comparison == 0 &&
            selected != null &&
            (candidate.sellArsPerUsd != selected.sellArsPerUsd ||
                candidate.buyArsPerUsd != selected.buyArsPerUsd)) {
          conflicting = true;
        }
      } on Object {
        discarded++;
        continue;
      }
    }
    if (selected == null || conflicting) {
      throw const AppFailure(AppFailureKind.invalidResponse);
    }
    return selected.withDiscardedHistoricalRows(discarded);
  }
}
