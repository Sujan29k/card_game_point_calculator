import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/match.dart';
import '../models/player.dart';
import '../models/round.dart';
import '../services/storage_service.dart';

class MatchProvider extends ChangeNotifier {
  GameMatch? _currentMatch;

  GameMatch? get currentMatch => _currentMatch;

  Future<void> loadActiveMatch() async {
    _currentMatch = await StorageService.instance.getActiveMatch();
    notifyListeners();
  }

  void createMatch({
    required String gameType,
    required List<String> playerNames,
    int? winningScore,
    int? roundCount,
    Map<String, int> bonusConfig = const {},
  }) {
    final uuid = const Uuid();
    final players = playerNames
        .map((name) => Player(id: uuid.v4(), name: name))
        .toList();
    _currentMatch = GameMatch(
      id: uuid.v4(),
      gameType: gameType,
      players: players,
      rounds: const [],
      startTime: DateTime.now(),
      winningScore: winningScore,
      roundCount: roundCount,
      bonusConfig: bonusConfig,
    );
    _autoSave();
    notifyListeners();
  }

  void addRound(GameRound round) {
    if (_currentMatch == null) return;
    final updatedRounds = [..._currentMatch!.rounds, round];
    _currentMatch = _currentMatch!.copyWith(rounds: updatedRounds);
    _autoSave();
    notifyListeners();
  }

  void editRound(int index, GameRound round) {
    if (_currentMatch == null) return;
    final updatedRounds = [..._currentMatch!.rounds];
    if (index < 0 || index >= updatedRounds.length) return;
    updatedRounds[index] = round.copyWith(isEdited: true);
    _currentMatch = _currentMatch!.copyWith(rounds: updatedRounds);
    _autoSave();
    notifyListeners();
  }

  void deleteRound(int index) {
    if (_currentMatch == null) return;
    final updatedRounds = [..._currentMatch!.rounds];
    if (index < 0 || index >= updatedRounds.length) return;
    updatedRounds.removeAt(index);
    _currentMatch = _currentMatch!.copyWith(rounds: updatedRounds);
    _autoSave();
    notifyListeners();
  }

  void endMatch() {
    if (_currentMatch == null) return;
    final totals = _currentMatch!.cumulativeScores;
    String? winnerId;
    int bestScore = -999999;
    totals.forEach((key, value) {
      if (value > bestScore) {
        bestScore = value;
        winnerId = key;
      }
    });
    _currentMatch = _currentMatch!.copyWith(
      winnerId: winnerId,
      endTime: DateTime.now(),
      isCompleted: true,
    );
    _saveCompletedMatch();
    _currentMatch = null;
    notifyListeners();
  }

  Future<void> clearActiveMatch() async {
    _currentMatch = null;
    await StorageService.instance.clearActiveMatch();
    notifyListeners();
  }

  // ─── Win / Round Condition Checks ──────────────────────────────────────────

  /// Returns true when the game has played at least [roundCount] rounds.
  /// Returns false if roundCount is null / 0 (unlimited game).
  bool hasReachedRoundCount() {
    if (_currentMatch == null) return false;
    final count = _currentMatch!.roundCount;
    if (count == null || count <= 0) return false;
    return _currentMatch!.rounds.length >= count;
  }

  /// Kept for Call Break — delegates to [hasReachedRoundCount].
  bool hasReachedWinningScore() => hasReachedRoundCount();

  /// The player whose regular-game cumulative score is currently highest.
  String? get currentLeaderId {
    if (_currentMatch == null) return null;
    final totals = _currentMatch!.cumulativeScores;
    if (totals.isEmpty) return null;
    return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  void _autoSave() {
    if (_currentMatch == null) return;
    StorageService.instance.saveActiveMatch(_currentMatch!);
  }

  void _saveCompletedMatch() {
    if (_currentMatch == null) return;
    StorageService.instance.saveMatch(_currentMatch!);
    StorageService.instance.clearActiveMatch();
  }
}
