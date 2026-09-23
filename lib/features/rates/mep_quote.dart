enum MepTimePrecision { instant, date }

class MepQuote {
  MepQuote({
    required this.sellArsPerUsd,
    required this.providerId,
    required this.quotedDate,
    required this.precision,
    required this.fetchedAtUtc,
    this.buyArsPerUsd,
    this.quotedAtUtc,
    this.discardedHistoricalRows = 0,
  }) {
    if (!sellArsPerUsd.isFinite ||
        sellArsPerUsd <= 0 ||
        (buyArsPerUsd != null &&
            (!buyArsPerUsd!.isFinite || buyArsPerUsd! <= 0)) ||
        providerId.trim().isEmpty ||
        (precision == MepTimePrecision.instant) != (quotedAtUtc != null) ||
        discardedHistoricalRows < 0 ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(quotedDate)) {
      throw ArgumentError('Cotización MEP inválida');
    }
    final parsedDay = DateTime.tryParse('${quotedDate}T00:00:00Z');
    if (parsedDay == null ||
        parsedDay.toIso8601String().substring(0, 10) != quotedDate) {
      throw ArgumentError('Fecha MEP inválida');
    }
  }

  final double sellArsPerUsd;
  final double? buyArsPerUsd;
  final String providerId;
  final String quotedDate;
  final MepTimePrecision precision;
  final DateTime? quotedAtUtc;
  final DateTime fetchedAtUtc;
  final int discardedHistoricalRows;

  MepQuote withDiscardedHistoricalRows(int count) => MepQuote(
    sellArsPerUsd: sellArsPerUsd,
    buyArsPerUsd: buyArsPerUsd,
    providerId: providerId,
    quotedDate: quotedDate,
    precision: precision,
    quotedAtUtc: quotedAtUtc,
    fetchedAtUtc: fetchedAtUtc,
    discardedHistoricalRows: count,
  );

  static String argentinaDate(DateTime utc) => utc
      .toUtc()
      .subtract(const Duration(hours: 3))
      .toIso8601String()
      .substring(0, 10);

  DateTime get ageReferenceUtc =>
      quotedAtUtc ?? DateTime.parse('${quotedDate}T03:00:00Z');

  bool isValidAt(DateTime nowUtc) {
    final day = argentinaDate(nowUtc);
    return precision == MepTimePrecision.date
        ? quotedDate.compareTo(day) <= 0
        : quotedAtUtc != null &&
              !quotedAtUtc!.isAfter(
                nowUtc.toUtc().add(const Duration(minutes: 5)),
              ) &&
              quotedDate == argentinaDate(quotedAtUtc!);
  }

  bool isStaleAt(DateTime nowUtc) =>
      nowUtc.toUtc().difference(ageReferenceUtc) > const Duration(hours: 48);

  int compareFreshness(MepQuote other) {
    final day = quotedDate.compareTo(other.quotedDate);
    if (day != 0) return day;
    if (precision != other.precision) {
      return precision == MepTimePrecision.instant ? 1 : -1;
    }
    if (quotedAtUtc != null) {
      final instant = quotedAtUtc!.compareTo(other.quotedAtUtc!);
      if (instant != 0) return instant;
    }
    if (providerId == 'dolar_api' && other.providerId != 'dolar_api') return 1;
    if (providerId != 'dolar_api' && other.providerId == 'dolar_api') return -1;
    return 0;
  }

  Map<String, Object?> toJson() => {
    'market': 'mep',
    'sellArsPerUsd': sellArsPerUsd,
    'buyArsPerUsd': buyArsPerUsd,
    'providerId': providerId,
    'quotedDate': quotedDate,
    'precision': precision.name,
    'quotedAtUtc': quotedAtUtc?.toIso8601String(),
    'fetchedAtUtc': fetchedAtUtc.toUtc().toIso8601String(),
    'discardedHistoricalRows': discardedHistoricalRows,
  };

  factory MepQuote.fromJson(Map<String, dynamic> json) {
    if (json['market'] != 'mep') throw const FormatException('market');
    return MepQuote(
      sellArsPerUsd: (json['sellArsPerUsd'] as num).toDouble(),
      buyArsPerUsd: (json['buyArsPerUsd'] as num?)?.toDouble(),
      providerId: json['providerId'] as String,
      quotedDate: json['quotedDate'] as String,
      precision: MepTimePrecision.values.byName(json['precision'] as String),
      quotedAtUtc: json['quotedAtUtc'] == null
          ? null
          : DateTime.parse(json['quotedAtUtc'] as String).toUtc(),
      fetchedAtUtc: DateTime.parse(json['fetchedAtUtc'] as String).toUtc(),
      discardedHistoricalRows: json['discardedHistoricalRows'] is int
          ? json['discardedHistoricalRows'] as int
          : 0,
    );
  }
}
