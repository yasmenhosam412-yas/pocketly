import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-defined payment / income sources (Cash, Vodafone Cash, etc.).
class PaymentMethodsStore extends ChangeNotifier {
  static const _prefsKey = 'payment_methods_custom_v1';

  /// Built-in suggestions shown on every picker.
  static const defaultPresets = [
    'Cash',
    'Salary',
    'Rents',
    'Visa Card',
    'Bank transfer',
    'Vodafone Cash',
    'InstaPay',
    'USD Wallet',
    'EUR Wallet',
    'Freelance',
    'Business',
    'Investment',
  ];

  List<String> _custom = [];

  List<String> get customMethods => List.unmodifiable(_custom);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _custom = [];
      notifyListeners();
      return;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _custom = decoded
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      _custom = [];
    }
    notifyListeners();
  }

  /// All chip labels: presets, saved custom, income DB sources, and [selected].
  List<String> optionsFor({
    Iterable<String> fromIncomes = const [],
    String? selected,
  }) {
    final combined = <String>{
      ...defaultPresets,
      ..._custom,
      ...fromIncomes.map((s) => s.trim()).where((s) => s.isNotEmpty),
    };
    final sel = selected?.trim();
    if (sel != null && sel.isNotEmpty) combined.add(sel);
    return combined.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  Future<bool> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final exists = defaultPresets.any(
          (p) => p.toLowerCase() == trimmed.toLowerCase(),
        ) ||
        _custom.any((c) => c.toLowerCase() == trimmed.toLowerCase());
    if (exists) {
      notifyListeners();
      return true;
    }
    _custom = [..._custom, trimmed];
    await _persist();
    return true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_custom));
    notifyListeners();
  }
}
