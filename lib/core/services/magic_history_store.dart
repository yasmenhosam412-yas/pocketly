import 'dart:convert';

import 'package:imrpo/core/models/magic_add_history_entry.dart';
import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MagicAddHistoryStore {
  static const String _storageKey = 'magic_add_history_v1';
  static const int _maxEntries = 200;

Future<void> removeEntry(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final history = await load();

  history.removeWhere((entry) => entry.id == id);

  await prefs.setString(
    _storageKey,
    jsonEncode(
      history.map((entry) => entry.toJson()).toList(),
    ),
  );
}

  Future<List<MagicAddHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded.map((item) {
        return MagicAddHistoryEntry.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEntries(List<ParsedFinancialEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await load();

    for (final entry in entries) {
      if (entry.amount == null || entry.amount! <= 0) continue;

      history.insert(0, MagicAddHistoryEntry.fromParsedEntry(entry));
    }

    await prefs.setString(
      _storageKey,
      jsonEncode(
        history.take(_maxEntries).map((entry) => entry.toJson()).toList(),
      ),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
