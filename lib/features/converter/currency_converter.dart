import '../currencies/currency.dart';
import '../rates/rate_snapshot.dart';
import '../rates/conversion_rates.dart';

enum ConversionFailure {
  invalidAmount,
  missingRate,
  invalidRate,
  resultTooLarge,
}

class ConversionException implements Exception {
  const ConversionException(this.failure);

  final ConversionFailure failure;
}

abstract final class CurrencyConverter {
  static const maxAmount = 1000000000.0;
  static const maxResult = 1000000000000.0;

  static double rate({
    required Currency from,
    required Currency to,
    required RateSnapshot? snapshot,
    ConversionRates? context,
  }) {
    if (from.code == to.code) {
      return 1;
    }
    final rates = context ?? ConversionRates(snapshot: snapshot);
    if (from.code == 'ARS' || to.code == 'ARS') {
      final mep = rates.mep?.sellArsPerUsd;
      if (mep == null) {
        throw const ConversionException(ConversionFailure.missingRate);
      }
      final fromRate = from.code == 'ARS'
          ? mep
          : from.code == 'USD'
          ? 1.0
          : rates.snapshot?.rates[from.code];
      final toRate = to.code == 'ARS'
          ? mep
          : to.code == 'USD'
          ? 1.0
          : rates.snapshot?.rates[to.code];
      if (fromRate == null || toRate == null) {
        throw const ConversionException(ConversionFailure.missingRate);
      }
      final result = toRate / fromRate;
      if (!result.isFinite || result <= 0) {
        throw const ConversionException(ConversionFailure.invalidRate);
      }
      return result;
    }
    final fromRate = rates.snapshot?.rates[from.code];
    final toRate = rates.snapshot?.rates[to.code];
    if (fromRate == null || toRate == null) {
      throw const ConversionException(ConversionFailure.missingRate);
    }
    if (!fromRate.isFinite ||
        fromRate <= 0 ||
        !toRate.isFinite ||
        toRate <= 0) {
      throw const ConversionException(ConversionFailure.invalidRate);
    }
    final result = toRate / fromRate;
    if (!result.isFinite || result <= 0) {
      throw const ConversionException(ConversionFailure.invalidRate);
    }
    return result;
  }

  static double convert({
    required double amount,
    required Currency from,
    required Currency to,
    required RateSnapshot? snapshot,
    ConversionRates? context,
  }) {
    if (!amount.isFinite || amount < 0 || amount > maxAmount) {
      throw const ConversionException(ConversionFailure.invalidAmount);
    }
    if (from.code == to.code) {
      return amount;
    }

    final result =
        amount * rate(from: from, to: to, snapshot: snapshot, context: context);
    if (!result.isFinite || result > maxResult) {
      throw const ConversionException(ConversionFailure.resultTooLarge);
    }
    return result;
  }

  static double roundForCurrency(double value, Currency currency) {
    if (!value.isFinite || value < 0) {
      throw const ConversionException(ConversionFailure.invalidAmount);
    }
    final factor = _powerOfTen(currency.decimalDigits);
    return (value * factor).round() / factor;
  }

  static double _powerOfTen(int exponent) {
    var result = 1.0;
    for (var index = 0; index < exponent; index++) {
      result *= 10;
    }
    return result;
  }
}
