import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/money_formatter.dart';
import '../../shared/rate_status.dart';
import 'mep_quote.dart';

class MepMetadata extends StatelessWidget {
  const MepMetadata({required this.quote, this.compact = false, super.key});

  final MepQuote quote;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = compact ? Theme.of(context).textTheme.bodySmall : null;
    final historical = quote.providerId == 'argentina_datos';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referencia ARS: dólar MEP · venta · ARS ${MoneyFormatter.formatRate(quote.sellArsPerUsd)} por USD',
          style: style,
        ),
        InkWell(
          onTap: () => launchUrl(
            historical
                ? Uri.https('argentinadatos.com')
                : Uri.https('dolarapi.com'),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            historical
                ? 'MEP desde respaldo histórico · ArgentinaDatos ↗'
                : 'MEP · DolarAPI ↗',
            style: style?.copyWith(decoration: TextDecoration.underline),
          ),
        ),
        Text(
          historical
              ? 'Cotización: ${quote.quotedDate.split('-').reversed.join('/')}'
              : 'Cotización: ${RateStatus.localDate(quote.quotedAtUtc!)}',
          style: style,
        ),
        if (quote.isStaleAt(DateTime.now().toUtc()))
          Text('MEP antiguo', style: style),
        if (quote.discardedHistoricalRows > 0)
          Text(
            'Histórico: ${quote.discardedHistoricalRows} registros descartados',
            style: style,
          ),
      ],
    );
  }
}
