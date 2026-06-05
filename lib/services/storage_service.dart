import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/match.dart';

class StorageService {
  StorageService._internal();

  static final StorageService instance = StorageService._internal();

  static const _matchesKey = 'matches';
  static const _activeMatchKey = 'active_match';

  Future<void> saveMatch(GameMatch match) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_matchesKey) ?? [];
    if (!ids.contains(match.id)) {
      ids.add(match.id);
      await prefs.setStringList(_matchesKey, ids);
    }
    await prefs.setString(_matchKey(match.id), jsonEncode(match.toJson()));
  }

  Future<GameMatch?> getMatch(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_matchKey(id));
    if (raw == null) return null;
    return GameMatch.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<List<GameMatch>> getAllMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_matchesKey) ?? [];
    final matches = <GameMatch>[];
    for (final id in ids) {
      final raw = prefs.getString(_matchKey(id));
      if (raw == null) continue;
      matches.add(GameMatch.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    }
    matches.sort((a, b) => b.startTime.compareTo(a.startTime));
    return matches;
  }

  Future<void> deleteMatch(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_matchesKey) ?? [];
    ids.remove(id);
    await prefs.setStringList(_matchesKey, ids);
    await prefs.remove(_matchKey(id));
  }

  Future<void> saveActiveMatch(GameMatch match) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeMatchKey, jsonEncode(match.toJson()));
  }

  Future<GameMatch?> getActiveMatch() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeMatchKey);
    if (raw == null) return null;
    return GameMatch.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearActiveMatch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeMatchKey);
  }

  Future<void> deleteMatchesOlderThan30Days() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_matchesKey) ?? [];
    final now = DateTime.now();
    final remaining = <String>[];
    for (final id in ids) {
      final raw = prefs.getString(_matchKey(id));
      if (raw == null) continue;
      final match = GameMatch.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final age = now.difference(match.startTime).inDays;
      if (age <= 30) {
        remaining.add(id);
      } else {
        await prefs.remove(_matchKey(id));
      }
    }
    await prefs.setStringList(_matchesKey, remaining);
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_matchesKey) ?? [];
    for (final id in ids) {
      await prefs.remove(_matchKey(id));
    }
    await prefs.remove(_matchesKey);
    await prefs.remove(_activeMatchKey);
  }

  /// Clears all completed match history but leaves the active match untouched.
  Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_matchesKey) ?? [];
    for (final id in ids) {
      await prefs.remove(_matchKey(id));
    }
    await prefs.remove(_matchesKey);
  }

  String _matchKey(String id) => 'match_$id';
}
