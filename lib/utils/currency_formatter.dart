import '../data/preferences_service.dart';

String formatMovementCurrency(double value, {bool showPositiveSign = false}) {
  final currency = PreferencesService.currencyNotifier.value;
  final symbol = currencySymbolFor(currency);
  final sign = value < 0
      ? '-'
      : showPositiveSign
      ? '+'
      : '';
  return '$sign${value.abs().toStringAsFixed(2)} $symbol';
}

String currencySymbolForCurrentPreference() {
  return currencySymbolFor(PreferencesService.currencyNotifier.value);
}

String currencySymbolFor(AppCurrency currency) {
  return switch (currency) {
    AppCurrency.eur => '€',
    AppCurrency.usd => r'$',
    AppCurrency.gbp => '£',
    AppCurrency.chf => 'CHF',
    AppCurrency.jpy => '¥',
  };
}
