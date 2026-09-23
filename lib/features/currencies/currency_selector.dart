import 'package:flutter/material.dart';

import '../../shared/widgets/currency_identity.dart';
import '../rates/rate_snapshot.dart';
import '../rates/conversion_rates.dart';
import 'currency.dart';
import 'currency_catalog.dart';
import 'currency_visual_identity.dart';

Future<Currency?> showCurrencySelector(
  BuildContext context, {
  required String title,
  String? selectedCode,
  RateSnapshot? snapshot,
  ConversionRates? rates,
  String? counterpartCode,
  Set<String> excludedCodes = const {},
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<Currency>(
    context: context,
    isScrollControlled: true,
    requestFocus: false,
    useSafeArea: true,
    builder: (context) => _CurrencySelector(
      title: title,
      selectedCode: selectedCode,
      snapshot: snapshot,
      rates: rates,
      counterpartCode: counterpartCode,
      excludedCodes: excludedCodes,
    ),
  );
}

class _CurrencySelector extends StatefulWidget {
  const _CurrencySelector({
    required this.title,
    required this.selectedCode,
    required this.snapshot,
    required this.rates,
    required this.counterpartCode,
    required this.excludedCodes,
  });

  final String title;
  final String? selectedCode;
  final RateSnapshot? snapshot;
  final ConversionRates? rates;
  final String? counterpartCode;
  final Set<String> excludedCodes;

  @override
  State<_CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<_CurrencySelector> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  String _query = '';
  bool _searchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    if (_searchVisible) {
      _searchFocus.unfocus();
      _searchController.clear();
      setState(() {
        _query = '';
        _searchVisible = false;
      });
      return;
    }

    setState(() => _searchVisible = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _searchVisible) {
        _searchFocus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final matches = CurrencyCatalog.search(_query);
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: _searchVisible
                      ? 'Cerrar búsqueda'
                      : 'Buscar monedas',
                  onPressed: _toggleSearch,
                  icon: Icon(_searchVisible ? Icons.search_off : Icons.search),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (_searchVisible) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                decoration: const InputDecoration(
                  labelText: 'Buscar código o nombre',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: matches.isEmpty
                ? const Center(child: Text('No hay monedas que coincidan.'))
                : ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final currency = matches[index];
                      final excluded = widget.excludedCodes.contains(
                        currency.code,
                      );
                      final unavailable =
                          widget.counterpartCode != null && widget.rates != null
                          ? !widget.rates!.canConvert(
                              widget.counterpartCode!,
                              currency.code,
                            )
                          : widget.snapshot != null &&
                                !widget.snapshot!.rates.containsKey(
                                  currency.code,
                                );
                      final identity = CurrencyVisualIdentity.of(currency.code);
                      final accent = identity.accentFor(
                        Theme.of(context).brightness,
                      );
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(color: accent, width: 4),
                          ),
                        ),
                        child: ListTile(
                          enabled: !excluded,
                          leading: CurrencyFlag(currency: currency),
                          title: Text('${currency.code} · ${currency.name}'),
                          subtitle: unavailable
                              ? Text(
                                  widget.rates?.unavailableReason(
                                        widget.counterpartCode ?? currency.code,
                                        currency.code,
                                      ) ??
                                      'Sin cotización disponible',
                                )
                              : excluded
                              ? const Text('Ya agregada')
                              : Text(currency.symbol ?? currency.code),
                          trailing: widget.selectedCode == currency.code
                              ? Icon(Icons.check_circle, color: accent)
                              : null,
                          onTap: excluded
                              ? null
                              : () => Navigator.pop(context, currency),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
