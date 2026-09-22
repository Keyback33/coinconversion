import 'package:flutter/material.dart';

import '../../features/currencies/currency.dart';
import '../../features/currencies/currency_visual_identity.dart';

class CurrencyFlag extends StatelessWidget {
  const CurrencyFlag({required this.currency, this.size = 32, super.key});

  final Currency currency;
  final double size;

  @override
  Widget build(BuildContext context) {
    final identity = CurrencyVisualIdentity.of(currency.code);
    final accent = identity.accentFor(Theme.of(context).brightness);
    return Semantics(
      image: true,
      label: 'Bandera de ${identity.issuerLabel}',
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: 2),
          ),
          child: identity.flagAsset.isEmpty
              ? Icon(Icons.public, size: size * 0.6, color: accent)
              : Image.asset(
                  identity.flagAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.public, size: size * 0.6, color: accent),
                ),
        ),
      ),
    );
  }
}

class CurrencyIdentity extends StatelessWidget {
  const CurrencyIdentity({
    required this.currency,
    this.compact = false,
    super.key,
  });

  final Currency currency;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${currency.code}, ${currency.name}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CurrencyFlag(currency: currency, size: compact ? 28 : 36),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.code,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (!compact)
                    Text(
                      currency.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
