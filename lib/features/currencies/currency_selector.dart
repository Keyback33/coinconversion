import 'package:flutter/material.dart';

import '../rates/rate_snapshot.dart';
import 'currency.dart';
import 'currency_catalog.dart';

Future<Currency?> showCurrencySelector(
  BuildContext context, {
  required String title,
  String? selectedCode,
  RateSnapshot? snapshot,
  Set<String> excludedCodes = const {},
}) {
  return showModalBottomSheet<Currency>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _CurrencySelector(
      title: title,
      selectedCode: selectedCode,
      snapshot: snapshot,
      excludedCodes: excludedCodes,
    ),
  );
}

class _CurrencySelector extends StatefulWidget {
  const _CurrencySelector({
    required this.title,
    required this.selectedCode,
    required this.snapshot,
    required this.excludedCodes,
  });

  final String title;
  final String? selectedCode;
  final RateSnapshot? snapshot;
  final Set<String> excludedCodes;

  @override
  State<_CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<_CurrencySelector> {
  String _query = '';

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
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Buscar código o nombre',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
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
                          widget.snapshot != null &&
                          !widget.snapshot!.rates.containsKey(currency.code);
                      return ListTile(
                        enabled: !excluded && !unavailable,
                        leading: CircleAvatar(child: Text(currency.code[0])),
                        title: Text('${currency.code} · ${currency.name}'),
                        subtitle: unavailable
                            ? const Text('Sin cotización disponible')
                            : Text(currency.symbol ?? currency.code),
                        trailing: widget.selectedCode == currency.code
                            ? const Icon(Icons.check)
                            : null,
                        onTap: excluded || unavailable
                            ? null
                            : () => Navigator.pop(context, currency),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
