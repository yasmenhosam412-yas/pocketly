import 'package:flutter/foundation.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/locale_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyPreferences extends ChangeNotifier {
  static const _storageKey = 'display_currency_code';

  String _displayCode = CurrencyConverter.defaultDisplayCode;

  String get displayCode => _displayCode;

  /// Loads display currency (always EGP).
  Future<void> load() async {
    _displayCode = CurrencyConverter.defaultDisplayCode;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_storageKey) != _displayCode) {
      await prefs.setString(_storageKey, _displayCode);
    }
  }

  set displayCode(String code) {
    final normalized = CurrencyConverter.defaultDisplayCode;
    if (_displayCode == normalized) return;
    _displayCode = normalized;
    notifyListeners();
    _persist(normalized);
  }

  Future<void> _persist(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, code);
  }

  double displayAmount(double baseAmount) =>
      CurrencyConverter.fromBase(baseAmount, _displayCode);

  String formatBase(double baseAmount) {
    final amount = displayAmount(baseAmount);
    return formatDisplayAmount(amount);
  }

  /// Formats [amount] already in display currency (EGP), without USD conversion.
  String formatDisplayAmount(double amount) {
    final l10n = lookupAppLocalizations(getIt<LocalePreferences>().locale);
    final symbol = localizeCurrencySymbol(l10n, _displayCode);
    final value = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
    return '$symbol$value';
  }
}
