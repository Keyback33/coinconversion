import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/rate_status.dart';
import 'rate_snapshot.dart';

class RateMetadata extends StatelessWidget {
  const RateMetadata({
    required this.snapshot,
    this.compact = false,
    this.codes,
    super.key,
  });

  final RateSnapshot snapshot;
  final bool compact;
  final Set<String>? codes;

  @override
  Widget build(BuildContext context) {
    final provider = RateStatus.providerName(snapshot.providerId);
    final alternative = RateStatus.isAlternative(snapshot.providerId);
    final style = compact ? Theme.of(context).textTheme.bodySmall : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _openAttribution(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Fuente: $provider${alternative ? ' (alternativa)' : ''} ↗',
              style: style?.copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ),
        if (snapshot.hasDailyDates) ...[
          for (final code in codes ?? snapshot.quotedDatesUtc.keys)
            if (code != 'ARS' && code != 'USD')
              Text(
                '$code: ${RateStatus.quotedDate(snapshot, code: code)}',
                style: style,
              ),
        ] else
          Text('Cotización: ${RateStatus.quotedDate(snapshot)}', style: style),
      ],
    );
  }

  Future<void> _openAttribution(BuildContext context) async {
    final opened = await launchUrl(
      RateStatus.providerUri(snapshot.providerId),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }
}
