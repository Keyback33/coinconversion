import 'package:http/http.dart' as http;

import '../../shared/app_failure.dart';
import 'mep_http_client.dart';
import 'mep_quote.dart';
import 'mep_rate_source.dart';

class DolarApiClient implements MepRateSource {
  DolarApiClient({
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
  String get providerId => 'dolar_api';

  @override
  Future<MepQuote> fetchLatest() async {
    final data = await _http.getJson(
      Uri.https('dolarapi.com', '/v1/dolares/bolsa'),
    );
    try {
      if (data is! Map<String, dynamic> ||
          data['casa'] != 'bolsa' ||
          data['moneda'] != 'USD') {
        throw const FormatException('market');
      }
      final sell = data['venta'];
      final buy = data['compra'];
      final rawTime = data['fechaActualizacion'];
      if (sell is! num ||
          rawTime is! String ||
          !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(rawTime)) {
        throw const FormatException('value');
      }
      final date = DateTime.parse(rawTime).toUtc();
      final quote = MepQuote(
        sellArsPerUsd: sell.toDouble(),
        buyArsPerUsd: buy is num && buy.isFinite && buy > 0
            ? buy.toDouble()
            : null,
        providerId: providerId,
        quotedDate: MepQuote.argentinaDate(date),
        precision: MepTimePrecision.instant,
        quotedAtUtc: date,
        fetchedAtUtc: _nowUtc().toUtc(),
      );
      if (!quote.isValidAt(_nowUtc())) throw const FormatException('future');
      return quote;
    } on Object {
      throw const AppFailure(AppFailureKind.invalidResponse);
    }
  }
}
