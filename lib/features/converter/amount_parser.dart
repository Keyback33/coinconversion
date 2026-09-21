enum AmountParseError { invalid, tooLong, tooManyDecimals, exceedsLimit }

class AmountParseResult {
  const AmountParseResult._({this.value, this.error, required this.isEmpty});

  const AmountParseResult.empty()
    : this._(value: null, error: null, isEmpty: true);

  const AmountParseResult.valid(double value)
    : this._(value: value, error: null, isEmpty: false);

  const AmountParseResult.invalid(AmountParseError error)
    : this._(value: null, error: error, isEmpty: false);

  final double? value;
  final AmountParseError? error;
  final bool isEmpty;

  bool get isValid => value != null && error == null;
}

abstract final class AmountParser {
  static const maxAmount = 1000000000.0;
  static const maxLength = 24;
  static const maxDecimalDigits = 6;

  static AmountParseResult parse(String input) {
    if (input.isEmpty) {
      return const AmountParseResult.empty();
    }
    if (input.length > maxLength) {
      return const AmountParseResult.invalid(AmountParseError.tooLong);
    }
    if (input.contains(',') && input.contains('.')) {
      return const AmountParseResult.invalid(AmountParseError.invalid);
    }
    if (!RegExp(r'^\d+(?:[,.]\d*)?$').hasMatch(input)) {
      return const AmountParseResult.invalid(AmountParseError.invalid);
    }

    final separatorIndex = input.indexOf(RegExp('[,.]'));
    if (separatorIndex >= 0 &&
        input.length - separatorIndex - 1 > maxDecimalDigits) {
      return const AmountParseResult.invalid(AmountParseError.tooManyDecimals);
    }

    final value = double.tryParse(input.replaceFirst(',', '.'));
    if (value == null || !value.isFinite) {
      return const AmountParseResult.invalid(AmountParseError.invalid);
    }
    if (value > maxAmount) {
      return const AmountParseResult.invalid(AmountParseError.exceedsLimit);
    }
    return AmountParseResult.valid(value);
  }

  static String normalizeSeparator(String input) =>
      input.replaceFirst('.', ',');
}
