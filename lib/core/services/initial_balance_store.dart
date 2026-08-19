import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/models/initial_balance_entry.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-user starting balances by payment source (Cash, Visa, etc.).
class InitialBalanceStore extends ChangeNotifier {
  static const _entriesKeyPrefix = 'initial_balance_entries_v2_';
  static const _legacyAmountKeyPrefix = 'initial_balance_amount_v1_';

  List<InitialBalanceEntry> _entries = [];

  List<InitialBalanceEntry> get entries => List.unmodifiable(_entries);

  double get amount =>
      _entries.fold<double>(0, (sum, entry) => sum + entry.amount);

  Map<String, double> get totalsBySource {
    final totals = <String, double>{};
    for (final entry in _entries) {
      final key = entry.source.trim();
      if (key.isEmpty) continue;
      totals[key] = (totals[key] ?? 0) + entry.amount;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  Future<void> load() async {
    final userId = SupabaseAuthHelper.userId;
    if (userId == null) {
      _entries = [];
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_entriesKeyPrefix$userId');
    if (raw != null && raw.isNotEmpty) {
      _entries = _parseEntries(raw);
    } else {
      final legacy = prefs.getDouble('$_legacyAmountKeyPrefix$userId') ?? 0;
      _entries = legacy > 0
          ? [
              InitialBalanceEntry(
                source: PaymentMethodsStore.defaultPresets.first,
                amount: legacy,
              ),
            ]
          : [];
    }
    notifyListeners();
  }

  Future<void> setEntries(List<InitialBalanceEntry> entries) async {
    final userId = SupabaseAuthHelper.userId;
    if (userId == null) return;

    _entries = _mergeBySource(entries);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_entriesKeyPrefix$userId',
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  void clearForUser() {
    _entries = [];
    notifyListeners();
  }

  List<InitialBalanceEntry> _parseEntries(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return _mergeBySource(
        list
            .map(
              (e) => InitialBalanceEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .where((e) => e.source.isNotEmpty && e.amount > 0)
            .toList(),
      );
    } catch (_) {
      return [];
    }
  }

  List<InitialBalanceEntry> _mergeBySource(List<InitialBalanceEntry> entries) {
    final merged = <String, double>{};
    for (final entry in entries) {
      final source = entry.source.trim();
      if (source.isEmpty || entry.amount <= 0) continue;
      merged[source] = (merged[source] ?? 0) + entry.amount;
    }
    final result = merged.entries
        .map((e) => InitialBalanceEntry(source: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => a.source.toLowerCase().compareTo(b.source.toLowerCase()));
    return result;
  }
}
