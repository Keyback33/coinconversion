import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
import 'favorite_rates_order.dart';
import 'rate_snapshot.dart';
import 'conversion_rates.dart';
import '../../shared/rate_status.dart';

class RatesList extends ConsumerStatefulWidget {
  const RatesList({required this.snapshot, this.rates, super.key});

  final RateSnapshot? snapshot;
  final ConversionRates? rates;

  @override
  ConsumerState<RatesList> createState() => _RatesListState();
}

class _RatesListState extends ConsumerState<RatesList> {
  bool _editing = false;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesControllerProvider).value;
    final reference = CurrencyCatalog.find(preferences.referenceCode)!;
    final visibleCodes = visibleFavoriteRates(
      preferences.favoriteCodes,
      preferences.referenceCode,
    );
    final sections = Theme.of(context).extension<AppSectionTheme>()!;
    return SectionCard(
      style: sections.rates,
      icon: Icons.show_chart,
      title: 'Cotizaciones',
      expanded: _expanded,
      onExpansionChanged: (value) => setState(() => _expanded = value),
      summary: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '1 ${reference.code} = … · Tabla general ${widget.snapshot == null ? 'no disponible' : 'disponible'} · MEP ${widget.rates?.mep == null ? 'no disponible' : 'disponible'}',
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                '1 ${reference.code} =',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Semantics(
                button: true,
                label: 'Moneda activa ${reference.code}, ${reference.name}',
                child: FilledButton.tonalIcon(
                  key: const Key('active-reference-button'),
                  onPressed: () => _selectReference(preferences),
                  icon: CurrencyFlag(currency: reference, size: 28),
                  label: Text('${reference.code} · Moneda activa'),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _editing = !_editing),
                icon: Icon(_editing ? Icons.done : Icons.edit_outlined),
                label: Text(_editing ? 'Listo' : 'Editar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (visibleCodes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No hay otras monedas para comparar. Podés agregar una cuando quieras.',
                textAlign: TextAlign.center,
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: visibleCodes.length,
              onReorder: (oldIndex, newIndex) =>
                  _reorderVisible(preferences, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final currency = CurrencyCatalog.find(visibleCodes[index])!;
                final identity = CurrencyVisualIdentity.of(currency.code);
                final accent = identity.accentFor(Theme.of(context).brightness);
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
                    subtitle: reference.code == 'ARS' || currency.code == 'ARS'
                        ? Text(
                            widget.rates?.canConvert(
                                      reference.code,
                                      currency.code,
                                    ) ==
                                    true
                                ? 'Referencia ARS: dólar MEP · venta'
                                : widget.rates?.unavailableReason(
                                        reference.code,
                                        currency.code,
                                      ) ??
                                      'MEP no disponible',
                          )
                        : null,
                    trailing: _editing
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Subir ${currency.code}',
                                onPressed: index == 0
                                    ? null
                                    : () =>
                                          _moveVisible(preferences, index, -1),
                                icon: const Icon(Icons.arrow_upward),
                              ),
                              IconButton(
                                tooltip: 'Bajar ${currency.code}',
                                onPressed: index == visibleCodes.length - 1
                                    ? null
                                    : () => _moveVisible(preferences, index, 1),
                                icon: const Icon(Icons.arrow_downward),
                              ),
                              IconButton(
                                tooltip: 'Quitar ${currency.code}',
                                onPressed: () => ref
                                    .read(
                                      preferencesControllerProvider.notifier,
                                    )
                                    .removeFavorite(currency.code),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                            ],
                          )
                        : Text(
                            '${_rateText(reference.code, currency.code)} ${currency.code}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          if (reference.code == 'ARS' || visibleCodes.contains('ARS')) ...[
            if (widget.rates?.mep != null)
              TextButton(
                onPressed: () => launchUrl(
                  Uri.https(
                    widget.rates!.mep!.providerId == 'dolar_api'
                        ? 'dolarapi.com'
                        : 'argentinadatos.com',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  'ARS: dólar MEP venta · ${widget.rates!.mep!.providerId == 'dolar_api' ? 'DolarAPI' : 'ArgentinaDatos'} ↗',
                ),
              )
            else
              const Text('MEP no disponible'),
          ],
          if (widget.snapshot != null &&
              (reference.code != 'ARS' ||
                  visibleCodes.any((code) => code != 'USD')))
            TextButton(
              onPressed: () => launchUrl(
                RateStatus.providerUri(widget.snapshot!.providerId),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(
                'Tabla general: ${RateStatus.providerName(widget.snapshot!.providerId)} ↗',
              ),
            ),
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
        CurrencyConverter.rate(
          from: from,
          to: to,
          snapshot: widget.snapshot,
          context: widget.rates,
        ),
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
      rates: widget.rates,
      counterpartCode: preferences.favoriteCodes.isEmpty
          ? null
          : preferences.favoriteCodes.first,
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
      rates: widget.rates,
      counterpartCode: preferences.referenceCode,
      excludedCodes: {...preferences.favoriteCodes, preferences.referenceCode},
    );
    if (selected != null) {
      ref
          .read(preferencesControllerProvider.notifier)
          .addFavorite(selected.code);
    }
  }

  void _reorderVisible(
    UserPreferences preferences,
    int oldIndex,
    int newIndex,
  ) {
    final favoriteCodes = reorderVisibleFavoriteRates(
      favoriteCodes: preferences.favoriteCodes,
      referenceCode: preferences.referenceCode,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    _saveFavoriteOrder(preferences, favoriteCodes);
  }

  void _moveVisible(UserPreferences preferences, int index, int offset) {
    final favoriteCodes = moveVisibleFavoriteRate(
      favoriteCodes: preferences.favoriteCodes,
      referenceCode: preferences.referenceCode,
      index: index,
      offset: offset,
    );
    _saveFavoriteOrder(preferences, favoriteCodes);
  }

  void _saveFavoriteOrder(
    UserPreferences preferences,
    List<String> favoriteCodes,
  ) {
    ref
        .read(preferencesControllerProvider.notifier)
        .update(preferences.copyWith(favoriteCodes: favoriteCodes));
  }
}
