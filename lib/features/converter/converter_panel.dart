import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../shared/money_formatter.dart';
import '../../shared/widgets/currency_identity.dart';
import '../../shared/widgets/section_card.dart';
import '../../theme/app_theme.dart';
import '../currencies/currency.dart';
import '../currencies/currency_catalog.dart';
import '../currencies/currency_selector.dart';
import '../currencies/currency_visual_identity.dart';
import '../rates/rate_metadata.dart';
import '../rates/conversion_rates.dart';
import '../rates/mep_metadata.dart';
import '../rates/rate_snapshot.dart';
import '../settings/user_preferences.dart';
import 'amount_parser.dart';
import 'currency_converter.dart';

class ConverterPanel extends ConsumerStatefulWidget {
  const ConverterPanel({required this.snapshot, this.rates, super.key});

  final RateSnapshot? snapshot;
  final ConversionRates? rates;

  @override
  ConsumerState<ConverterPanel> createState() => _ConverterPanelState();
}

class _ConverterPanelState extends ConsumerState<ConverterPanel> {
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_rebuild);
    _amountFocus.addListener(_normalizeOnBlur);
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_rebuild)
      ..dispose();
    _amountFocus
      ..removeListener(_normalizeOnBlur)
      ..dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _normalizeOnBlur() {
    if (!_amountFocus.hasFocus) {
      final normalized = AmountParser.normalizeSeparator(
        _amountController.text,
      );
      if (normalized != _amountController.text) {
        _amountController.value = TextEditingValue(
          text: normalized,
          selection: TextSelection.collapsed(offset: normalized.length),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesControllerProvider).value;
    final from = CurrencyCatalog.find(preferences.converterFromCode)!;
    final to = CurrencyCatalog.find(preferences.converterToCode)!;
    final result = _calculate(from, to);
    final sections = Theme.of(context).extension<AppSectionTheme>()!;

    return SectionCard(
      style: sections.converter,
      icon: Icons.swap_horiz,
      title: 'Conversor',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('amount-field'),
            controller: _amountController,
            focusNode: _amountFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            maxLength: AmountParser.maxLength,
            decoration: InputDecoration(
              labelText: 'Monto',
              hintText: '100',
              border: const OutlineInputBorder(),
              errorText: result.inputError,
              helperText: 'Sin separadores de miles; usá coma o punto decimal.',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CurrencyButton(
                  label: 'Desde',
                  currency: from,
                  onPressed: () =>
                      _selectCurrency(preferences, selectingFrom: true),
                ),
              ),
              IconButton(
                tooltip: 'Invertir monedas',
                onPressed: () => _swap(preferences),
                icon: const Icon(Icons.swap_horiz),
              ),
              Expanded(
                child: _CurrencyButton(
                  label: 'Hacia',
                  currency: to,
                  onPressed: () =>
                      _selectCurrency(preferences, selectingFrom: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.display ?? '—',
                      key: const Key('conversion-result'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (result.belowMinimum)
                      Text('Menor que ${to.code} ${_minimum(to)}'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copiar resultado',
                onPressed: result.display == null
                    ? null
                    : () => _copy(result.display!),
                icon: const Icon(Icons.copy),
              ),
            ],
          ),
          if (result.rateText != null) ...[
            const SizedBox(height: 8),
            Text('1 ${from.code} = ${result.rateText} ${to.code}'),
          ],
          const SizedBox(height: 12),
          if (from.code == to.code)
            const Text('Conversión directa; no requiere cotización.')
          else ...[
            if (from.code == 'ARS' || to.code == 'ARS')
              if (widget.rates?.mep != null)
                MepMetadata(quote: widget.rates!.mep!, compact: true)
              else
                const Text('MEP no disponible'),
            if (!(from.code == 'ARS' && to.code == 'USD') &&
                !(from.code == 'USD' && to.code == 'ARS'))
              if (widget.snapshot != null)
                RateMetadata(
                  snapshot: widget.snapshot!,
                  compact: true,
                  codes: {from.code, to.code},
                )
              else
                const Text('Tabla general no disponible'),
          ],
        ],
      ),
    );
  }

  _ConversionView _calculate(Currency from, Currency to) {
    final parsed = AmountParser.parse(_amountController.text);
    if (parsed.isEmpty) {
      return const _ConversionView();
    }
    if (!parsed.isValid) {
      return _ConversionView(inputError: _inputError(parsed.error!));
    }
    try {
      final rate = CurrencyConverter.rate(
        from: from,
        to: to,
        snapshot: widget.snapshot,
        context: widget.rates,
      );
      final raw = CurrencyConverter.convert(
        amount: parsed.value!,
        from: from,
        to: to,
        snapshot: widget.snapshot,
        context: widget.rates,
      );
      final rounded = CurrencyConverter.roundForCurrency(raw, to);
      return _ConversionView(
        display: MoneyFormatter.formatAmount(raw, to),
        rateText: MoneyFormatter.formatRate(rate),
        belowMinimum: raw > 0 && rounded == 0,
      );
    } on ConversionException catch (error) {
      return _ConversionView(
        inputError: switch (error.failure) {
          ConversionFailure.missingRate =>
            widget.rates?.unavailableReason(from.code, to.code) ??
                'No hay cotización para esta moneda.',
          ConversionFailure.resultTooLarge =>
            'El importe supera el límite permitido.',
          _ => 'No se pudo usar esta cotización.',
        },
      );
    }
  }

  String _inputError(AmountParseError error) {
    return switch (error) {
      AmountParseError.tooManyDecimals => 'Usá hasta seis decimales.',
      AmountParseError.tooLong ||
      AmountParseError.exceedsLimit => 'El importe supera el límite permitido.',
      AmountParseError.invalid => 'Usá un solo separador decimal, sin miles.',
    };
  }

  String _minimum(Currency currency) => currency.decimalDigits == 0
      ? '1'
      : '0,${'0' * (currency.decimalDigits - 1)}1';

  Future<void> _selectCurrency(
    UserPreferences preferences, {
    required bool selectingFrom,
  }) async {
    final selected = await showCurrencySelector(
      context,
      title: selectingFrom ? 'Convertir desde' : 'Convertir hacia',
      selectedCode: selectingFrom
          ? preferences.converterFromCode
          : preferences.converterToCode,
      snapshot: widget.snapshot,
      rates: widget.rates,
      counterpartCode: selectingFrom
          ? preferences.converterToCode
          : preferences.converterFromCode,
    );
    if (selected == null) {
      return;
    }
    ref
        .read(preferencesControllerProvider.notifier)
        .update(
          selectingFrom
              ? preferences.copyWith(converterFromCode: selected.code)
              : preferences.copyWith(converterToCode: selected.code),
        );
  }

  void _swap(UserPreferences preferences) {
    ref
        .read(preferencesControllerProvider.notifier)
        .update(
          preferences.copyWith(
            converterFromCode: preferences.converterToCode,
            converterToCode: preferences.converterFromCode,
          ),
        );
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resultado copiado.')));
    }
  }
}

class _CurrencyButton extends StatelessWidget {
  const _CurrencyButton({
    required this.label,
    required this.currency,
    required this.onPressed,
  });

  final String label;
  final Currency currency;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final identity = CurrencyVisualIdentity.of(currency.code);
    final accent = identity.accentFor(Theme.of(context).brightness);
    return Semantics(
      button: true,
      label: '$label: ${currency.code}, ${currency.name}',
      excludeSemantics: true,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          side: BorderSide(color: accent, width: 2),
          minimumSize: const Size(0, 64),
        ),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            CurrencyIdentity(currency: currency, compact: true),
          ],
        ),
      ),
    );
  }
}

class _ConversionView {
  const _ConversionView({
    this.display,
    this.rateText,
    this.inputError,
    this.belowMinimum = false,
  });

  final String? display;
  final String? rateText;
  final String? inputError;
  final bool belowMinimum;
}
