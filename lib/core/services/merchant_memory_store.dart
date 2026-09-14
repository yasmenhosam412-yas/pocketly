import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MerchantMemoryEntry {
  final String category;
  final String? paidFrom;

  const MerchantMemoryEntry({
    required this.category,
    this.paidFrom,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        if (paidFrom != null && paidFrom!.trim().isNotEmpty)
          'paidFrom': paidFrom,
      };

  factory MerchantMemoryEntry.fromJson(Map<String, dynamic> json) {
    return MerchantMemoryEntry(
      category: (json['category'] as String? ?? 'Other').trim(),
      paidFrom: (json['paidFrom'] as String?)?.trim(),
    );
  }
}

/// Remembers merchant/title → expense category + paid-from for SMS/paste import.
class MerchantMemoryStore extends ChangeNotifier {
  static const _prefsKey = 'merchant_memory_v1';

  Map<String, MerchantMemoryEntry> _byKey = {};

  Map<String, MerchantMemoryEntry> get entries => Map.unmodifiable(_byKey);

  static String normalizeKey(String? title) {
    final t = (title ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[\u200e\u200f\u0640]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (t.isEmpty) return '';
    if (t.length > 64) return t.substring(0, 64);
    return t;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _byKey = {};
      notifyListeners();
      return;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _byKey = {
        for (final e in decoded.entries)
          e.key: MerchantMemoryEntry.fromJson(
            Map<String, dynamic>.from(e.value as Map),
          ),
      };
    } catch (_) {
      _byKey = {};
    }
    notifyListeners();
  }

  MerchantMemoryEntry? lookup(String? title) {
    final key = normalizeKey(title);
    if (key.isEmpty) return null;
    return _byKey[key];
  }

  Future<void> remember({
    required String? title,
    required String category,
    String? paidFrom,
  }) async {
    final key = normalizeKey(title);
    if (key.isEmpty) return;
    final cat = category.trim();
    if (cat.isEmpty) return;
    _byKey[key] = MerchantMemoryEntry(
      category: cat,
      paidFrom: paidFrom?.trim().isEmpty == true ? null : paidFrom?.trim(),
    );
    await _persist();
  }

  Future<void> clear() async {
    _byKey = {};
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        for (final e in _byKey.entries) e.key: e.value.toJson(),
      }),
    );
    notifyListeners();
  }
}
