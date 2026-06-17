import '../data/preferences_service.dart';

String formatMovementCurrency(
  double value, {
  bool showPositiveSign = false,
}) {
  final currency = PreferencesService.currencyNotifier.value;
  final symbol = _currencySymbol(currency);
  final sign = value < 0
      ? '-'
      : showPositiveSign
      ? '+'
      : '';
  return '$sign${value.abs().toStringAsFixed(2)} $symbol';
}

String _currencySymbol(AppCurrency currency) {
  return switch (currency) {
    AppCurrency.eur => '€',
    AppCurrency.usd => r'$',
    AppCurrency.gbp => '£',
    AppCurrency.chf => 'CHF',
    AppCurrency.jpy => '¥',
  };
}
