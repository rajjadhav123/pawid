import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_entry.dart';
import '../config/constants.dart';

/// Persists detection history (up to [kMaxHistory] entries) in SharedPreferences.
class HistoryService {
  static const String _historyKey = 'detection_history';

  // ─── Read ──────────────────────────────────────────────────────────────────

  Future<List<HistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    final entries = <HistoryEntry>[];
    for (final item in raw) {
      try {
        entries.add(HistoryEntry.fromJson(json.decode(item)));
      } catch (_) {
        // Skip corrupted entries silently
      }
    }
    // Most recent first
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  // ─── Write ─────────────────────────────────────────────────────────────────

  Future<void> addEntry(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadHistory();

    // Prepend new entry
    existing.insert(0, entry);

    // Cap at max
    final trimmed = existing.take(kMaxHistory).toList();

    await prefs.setStringList(
      _historyKey,
      trimmed.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteEntry(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadHistory();
    final updated = existing.where((e) => e.id != id).toList();
    await prefs.setStringList(
      _historyKey,
      updated.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // ─── Server URL ────────────────────────────────────────────────────────────

  Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kServerUrlKey) ?? kDefaultServerUrl;
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kServerUrlKey, url);
  }
}