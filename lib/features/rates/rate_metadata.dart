import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/rate_status.dart';
import 'rate_snapshot.dart';

class RateMetadata extends StatelessWidget {
  const RateMetadata({required this.snapshot, this.compact = false, super.key});

  final RateSnapshot snapshot;
  final bool compact;

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
        Text(
          'Extraído: ${RateStatus.localDate(snapshot.fetchedAtUtc)} · hora local',
          style: style,
        ),
        Text(
          'Cotización del provider: ${RateStatus.localDate(snapshot.quotedAtUtc)}',
          style: style,
        ),
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
