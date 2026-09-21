import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../shared/money_formatter.dart';
import '../../shared/widgets/currency_identity.dart';
import '../../shared/widgets/section_card.dart';
import '../../theme/app_theme.dart';
import '../converter/currency_converter.dart';
import '../currencies/currency_catalog.dart';
import '../currencies/currency_selector.dart';
import '../currencies/currency_visual_identity.dart';
import '../settings/user_preferences.dart';
import 'rate_snapshot.dart';

class RatesList extends ConsumerStatefulWidget {
  const RatesList({required this.snapshot, super.key});

  final RateSnapshot? snapshot;

  @override
  ConsumerState<RatesList> createState() => _RatesListState();
}

class _RatesListState extends ConsumerState<RatesList> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesControllerProvider).value;
    final reference = CurrencyCatalog.find(preferences.referenceCode)!;
    final sections = Theme.of(context).extension<AppSectionTheme>()!;
    return SectionCard(
      style: sections.rates,
      icon: Icons.show_chart,
      title: 'Cotizaciones',
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  'Cotizaciones por 1 ${reference.code}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => _selectReference(preferences),
                      child: Text(reference.code),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _editing = !_editing),
                      icon: Icon(_editing ? Icons.done : Icons.edit_outlined),
                      label: Text(_editing ? 'Listo' : 'Editar'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (preferences.favoriteCodes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No hay monedas favoritas. Podés agregar una cuando quieras.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: preferences.favoriteCodes.length,
                onReorder: ref
                    .read(preferencesControllerProvider.notifier)
                    .reorderFavorite,
                itemBuilder: (context, index) {
                  final currency = CurrencyCatalog.find(
                    preferences.favoriteCodes[index],
                  )!;
                  final identity = CurrencyVisualIdentity.of(currency.code);
                  final accent = identity.accentFor(
                    Theme.of(context).brightness,
                  );
                  return Container(
                    key: ValueKey(currency.code),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                      border: Border(left: BorderSide(color: accent, width: 4)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.only(left: 8, right: 4),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_editing)
                            ReorderableDragStartListener(
                              index: index,
                              child: const Tooltip(
                                message: 'Reordenar',
                                child: Icon(Icons.drag_handle),
                              ),
                            ),
                          CurrencyFlag(currency: currency),
                        ],
                      ),
                      title: Text('${currency.code} · ${currency.name}'),
                      subtitle: currency.code == 'ARS'
                          ? const Text('Referencia fiat estándar del provider')
                          : null,
                      trailing: _editing
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Subir ${currency.code}',
                                  onPressed: index == 0
                                      ? null
                                      : () => ref
                                            .read(
                                              preferencesControllerProvider
                                                  .notifier,
                                            )
                                            .moveFavorite(index, -1),
                                  icon: const Icon(Icons.arrow_upward),
                                ),
                                IconButton(
                                  tooltip: 'Bajar ${currency.code}',
                                  onPressed:
                                      index ==
                                          preferences.favoriteCodes.length - 1
                                      ? null
                                      : () => ref
                                            .read(
                                              preferencesControllerProvider
                                                  .notifier,
                                            )
                                            .moveFavorite(index, 1),
                                  icon: const Icon(Icons.arrow_downward),
                                ),
                                IconButton(
                                  tooltip: 'Quitar ${currency.code}',
                                  onPressed: () => ref
                                      .read(
                                        preferencesControllerProvider.notifier,
                                      )
                                      .removeFavorite(currency.code),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _rateText(reference.code, currency.code),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _addFavorite(preferences),
              icon: const Icon(Icons.add),
              label: const Text('Agregar moneda'),
            ),
          ],
      ),
    );
  }

  String _rateText(String fromCode, String toCode) {
    final from = CurrencyCatalog.find(fromCode)!;
    final to = CurrencyCatalog.find(toCode)!;
    try {
      return MoneyFormatter.formatRate(
        CurrencyConverter.rate(from: from, to: to, snapshot: widget.snapshot),
      );
    } on ConversionException {
      return '—';
    }
  }

  Future<void> _selectReference(UserPreferences preferences) async {
    final selected = await showCurrencySelector(
      context,
      title: 'Moneda de referencia',
      selectedCode: preferences.referenceCode,
      snapshot: widget.snapshot,
    );
    if (selected != null) {
      ref
          .read(preferencesControllerProvider.notifier)
          .update(preferences.copyWith(referenceCode: selected.code));
    }
  }

  Future<void> _addFavorite(UserPreferences preferences) async {
    final selected = await showCurrencySelector(
      context,
      title: 'Agregar moneda',
      snapshot: widget.snapshot,
      excludedCodes: preferences.favoriteCodes.toSet(),
    );
    if (selected != null) {
      ref
          .read(preferencesControllerProvider.notifier)
          .addFavorite(selected.code);
    }
  }
}
