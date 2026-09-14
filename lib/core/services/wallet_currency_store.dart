import 'package:flutter/foundation.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/features/budgets/domain/services/budget_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Maps wallet / payment sources to a display currency (EGP / USD / EUR).
class WalletCurrencyStore extends ChangeNotifier {
  static const _prefsKey = 'wallet_currency_map_v1';

  static const usdWallet = 'USD Wallet';
  static const eurWallet = 'EUR Wallet';

  Map<String, String> _bySource = {
    usdWallet: 'USD',
    eurWallet: 'EUR',
  };

  Map<String, String> get bySource => Map.unmodifiable(_bySource);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _bySource = {
        usdWallet: 'USD',
        eurWallet: 'EUR',
      };
      notifyListeners();
      return;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _bySource = {
        for (final e in decoded.entries)
          e.key: (e.value?.toString() ?? CurrencyConverter.defaultDisplayCode),
      };
      _bySource.putIfAbsent(usdWallet, () => 'USD');
      _bySource.putIfAbsent(eurWallet, () => 'EUR');
    } catch (_) {
      _bySource = {
        usdWallet: 'USD',
        eurWallet: 'EUR',
      };
    }
    notifyListeners();
  }

  String currencyFor(String source) {
    final key = BudgetCalculator.categoryKey(source);
    for (final entry in _bySource.entries) {
      if (BudgetCalculator.categoryKey(entry.key) == key) {
        return entry.value;
      }
    }
    final lower = source.toLowerCase();
    if (lower.contains('usd') || lower.contains('dollar')) return 'USD';
    if (lower.contains('eur') || lower.contains('euro')) return 'EUR';
    return CurrencyConverter.defaultDisplayCode;
  }

  Future<void> setCurrency(String source, String currencyCode) async {
    final code = CurrencyConverter.byCode(currencyCode).code;
    _bySource[source.trim()] = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_bySource));
  }

  /// Format [baseAmount] in the wallet's currency, with EGP equivalent when
  /// the pocket is not EGP.
  String formatPocket(
    double baseAmount, {
    required String source,
    required String Function(double egpAmount) formatEgp,
  }) {
    final code = currencyFor(source);
    final native = CurrencyConverter.fromBase(baseAmount, code);
    final nativeLabel = CurrencyConverter.format(native, code);
    if (code == CurrencyConverter.defaultDisplayCode) {
      return formatEgp(CurrencyConverter.fromBase(
        baseAmount,
        CurrencyConverter.defaultDisplayCode,
      ));
    }
    final egp = CurrencyConverter.fromBase(
      baseAmount,
      CurrencyConverter.defaultDisplayCode,
    );
    return '$nativeLabel · ${formatEgp(egp)}';
  }
}
