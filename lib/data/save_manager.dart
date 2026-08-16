import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_save.dart';

/// Singleton that manages persistent game state via SharedPreferences.
class SaveManager extends ChangeNotifier {
  SaveManager._();
  static final SaveManager instance = SaveManager._();

  late SharedPreferences _prefs;
  late GameSave save;
  Future<void> _writeQueue = Future<void>.value();

  static const _keyBestScore = 'bestScore';
  static const _keyBestScoresByGoal = 'bestScoresByGoal';
  static const _keyCompletedGameCount = 'completedGameCount';
  static const _keyIsDarkTheme = 'isDarkTheme';
  static const _keyAdsRemoved = 'adsRemoved';
  static const _keyGameSession = 'gameSession';

  // Legacy keys kept only for migrating saves from the first implementation.
  static const _legacyCurrentScore = 'currentScore';
  static const _legacyBoardState = 'boardState';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    save = _load();
    await persist();
  }

  GameSave _load() {
    final bestScore = (_prefs.getInt(_keyBestScore) ?? 0).clamp(0, 1 << 53);
    final bestScoresByGoal = _loadBestScores(bestScore);
    final completedGameCount =
        (_prefs.getInt(_keyCompletedGameCount) ?? 0).clamp(0, 1 << 53);
    final isDarkTheme = _prefs.getBool(_keyIsDarkTheme) ?? false;
    final adsRemoved = _prefs.getBool(_keyAdsRemoved) ?? false;

    List<int>? boardState;
    var currentScore = 0;
    var goal = 2048;
    var gameStatus = 'playing';
    var hasWon = false;

    final sessionRaw = _prefs.getString(_keyGameSession);
    if (sessionRaw != null) {
      try {
        final session = jsonDecode(sessionRaw) as Map<String, dynamic>;
        final candidate = List<int>.from(session['board'] as List);
        final candidateScore = session['score'] as int;
        final candidateGoal = session['goal'] as int? ?? 2048;
        final candidateStatus = session['status'] as String;
        final candidateHasWon = session['hasWon'] as bool;

        if (_isValidBoard(candidate) &&
            candidateScore >= 0 &&
            _isValidGoal(candidateGoal) &&
            _isValidStatus(candidateStatus)) {
          boardState = candidate;
          currentScore = candidateScore;
          goal = candidateGoal;
          gameStatus = candidateStatus;
          hasWon = candidateHasWon;
        }
      } catch (_) {
        // Corrupted snapshot — start a fresh session.
      }
    } else {
      // Migrate the original separate board/score keys.
      final legacyBoardRaw = _prefs.getString(_legacyBoardState);
      if (legacyBoardRaw != null) {
        try {
          final candidate = List<int>.from(jsonDecode(legacyBoardRaw) as List);
          final candidateScore = _prefs.getInt(_legacyCurrentScore) ?? 0;
          if (_isValidBoard(candidate) && candidateScore >= 0) {
            boardState = candidate;
            currentScore = candidateScore;
            hasWon = candidate.any((value) => value >= 2048);
            gameStatus = hasWon ? 'won' : 'playing';
          }
        } catch (_) {
          // Invalid legacy data — start a fresh session.
        }
      }
    }

    return GameSave(
      bestScore: bestScore,
      bestScoresByGoal: bestScoresByGoal,
      currentScore: currentScore,
      goal: goal,
      completedGameCount: completedGameCount,
      isDarkTheme: isDarkTheme,
      adsRemoved: adsRemoved,
      boardState: boardState,
      gameStatus: gameStatus,
      hasWon: hasWon,
    );
  }

  static bool _isValidGoal(int goal) =>
      const <int>{256, 512, 1024, 2048}.contains(goal);

  Map<int, int> _loadBestScores(int legacyBest) {
    final scores = <int, int>{2048: legacyBest};
    final raw = _prefs.getString(_keyBestScoresByGoal);
    if (raw == null) return scores;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final goal = int.tryParse(entry.key);
        final score = entry.value;
        if (goal != null && _isValidGoal(goal) && score is int && score >= 0) {
          scores[goal] = score;
        }
      }
    } catch (_) {}
    return scores;
  }

  static bool _isValidStatus(String value) =>
      value == 'playing' || value == 'won' || value == 'lost';

  static bool _isValidBoard(List<int> board) {
    if (board.length != 16) return false;
    return board.every(
      (value) => value == 0 || (value > 0 && (value & (value - 1)) == 0),
    );
  }

  /// Persist an immutable snapshot. Writes are serialized so rapid moves cannot
  /// finish out of order and overwrite a newer board.
  Future<void> persist() {
    final bestScore = save.bestScore;
    final bestScoresByGoal = Map<int, int>.from(save.bestScoresByGoal);
    final completedGameCount = save.completedGameCount;
    final isDarkTheme = save.isDarkTheme;
    final adsRemoved = save.adsRemoved;
    final board = save.boardState == null
        ? null
        : List<int>.from(save.boardState!);
    final score = save.currentScore;
    final goal = save.goal;
    final status = save.gameStatus;
    final hasWon = save.hasWon;

    notifyListeners();

    final previousWrite = _writeQueue;
    _writeQueue = () async {
      try {
        await previousWrite;
      } catch (_) {
        // A failed older write must not block newer state from being saved.
      }

      await _prefs.setInt(_keyBestScore, bestScore);
      await _prefs.setString(
        _keyBestScoresByGoal,
        jsonEncode(bestScoresByGoal.map((key, value) => MapEntry('$key', value))),
      );
      await _prefs.setInt(_keyCompletedGameCount, completedGameCount);
      await _prefs.setBool(_keyIsDarkTheme, isDarkTheme);
      await _prefs.setBool(_keyAdsRemoved, adsRemoved);

      if (board == null) {
        await _prefs.remove(_keyGameSession);
      } else {
        await _prefs.setString(
          _keyGameSession,
          jsonEncode({
            'board': board,
            'score': score,
            'goal': goal,
            'status': status,
            'hasWon': hasWon,
          }),
        );
      }

      await _prefs.remove(_legacyCurrentScore);
      await _prefs.remove(_legacyBoardState);
    }();
    return _writeQueue;
  }

  int bestScoreFor(int goal) => save.bestScoresByGoal[goal] ?? 0;

  /// Record one complete controller transition and update the goal's BEST.
  Future<void> recordGameState({
    required List<int> board,
    required int score,
    required int goal,
    required String status,
    required bool hasWon,
  }) {
    final previousBest = bestScoreFor(goal);
    save.bestScoresByGoal[goal] = score > previousBest ? score : previousBest;
    save.bestScore = bestScoreFor(2048);
    save.goal = goal;
    save.hasWon = hasWon;
    save.gameStatus = status;

    if (status == 'lost') {
      save.boardState = null;
      save.currentScore = 0;
    } else {
      save.boardState = List<int>.from(board);
      save.currentScore = score;
    }

    return persist();
  }

  /// Counts a completed (lost) game and indicates when an ad is due.
  Future<bool> recordCompletedGame() async {
    save.completedGameCount++;
    await persist();
    return !save.adsRemoved && save.completedGameCount % 4 == 0;
  }

  Future<void> setAdsRemoved(bool value) {
    save.adsRemoved = value;
    return persist();
  }

  Future<void> clearBoardState() {
    save.boardState = null;
    save.currentScore = 0;
    save.gameStatus = 'playing';
    save.hasWon = false;
    return persist();
  }

  bool get hasActiveSession => save.boardState != null;

  /// Wait for all queued disk writes to finish.
  Future<void> flush() => _writeQueue;

  Future<void> resetAll() async {
    save = GameSave();
    await persist();
  }
}
