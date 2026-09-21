class Currency {
  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.decimalDigits,
  });

  final String code;
  final String name;
  final String? symbol;
  final int decimalDigits;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Currency &&
            code == other.code &&
            name == other.name &&
            symbol == other.symbol &&
            decimalDigits == other.decimalDigits;
  }

  @override
  int get hashCode => Object.hash(code, name, symbol, decimalDigits);
}
