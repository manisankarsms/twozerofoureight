import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/tile.dart';

enum MoveDirection { up, down, left, right }

enum GameStatus { playing, won, lost }

/// Observable game state for 2048.
/// The UI listens to this via ChangeNotifier for rebuilds.
class GameController extends ChangeNotifier {
  static const int gridSize = 4;
  static const supportedGoals = <int>[256, 512, 1024, 2048];

  GameController({int goal = 2048})
      : goal = supportedGoals.contains(goal) ? goal : 2048;

  final int goal;
  final Random _random = Random();
  int _nextTileId = 0;

  List<Tile> tiles = [];
  int score = 0;
  GameStatus status = GameStatus.playing;
  bool hasWon = false;

  void newGame() {
    tiles = [];
    score = 0;
    status = GameStatus.playing;
    hasWon = false;
    _nextTileId = 0;
    _spawnTile();
    _spawnTile();
    notifyListeners();
  }

  /// Restore a validated saved session, including its win-overlay state.
  void restoreFromBoard(
    List<int> flatBoard,
    int savedScore, {
    required GameStatus savedStatus,
    required bool savedHasWon,
  }) {
    if (flatBoard.length != gridSize * gridSize) {
      throw ArgumentError.value(flatBoard.length, 'flatBoard.length');
    }

    tiles = [];
    score = savedScore;
    status = savedStatus;
    hasWon = savedHasWon;
    _nextTileId = 0;

    for (int i = 0; i < flatBoard.length; i++) {
      final value = flatBoard[i];
      if (value != 0) {
        tiles.add(Tile(
          row: i ~/ gridSize,
          col: i % gridSize,
          value: value,
          id: _nextTileId++,
        ));
        if (value >= goal) hasWon = true;
      }
    }

    // A playing snapshot may have become terminal immediately after its last
    // spawn. Detect that before allowing the player to resume.
    _checkGameState();
    notifyListeners();
  }

  List<int> get flatBoard {
    final board = List.filled(gridSize * gridSize, 0);
    for (final tile in tiles) {
      board[tile.row * gridSize + tile.col] = tile.value;
    }
    return board;
  }

  /// Attempt a move. Returns true if the board changed.
  bool move(MoveDirection direction) {
    // The win overlay must be acknowledged before further movement.
    if (status != GameStatus.playing) return false;

    for (final tile in tiles) {
      tile.merged = false;
      tile.isNew = false;
    }

    final oldStatus = status;
    final bool moved;
    switch (direction) {
      case MoveDirection.up:
        moved = _moveUp();
      case MoveDirection.down:
        moved = _moveDown();
      case MoveDirection.left:
        moved = _moveLeft();
      case MoveDirection.right:
        moved = _moveRight();
    }

    if (moved) {
      _spawnTile();
      _checkGameState();
      notifyListeners();
    } else {
      // A no-op swipe on a full board must still transition to game over.
      _checkGameState();
      if (status != oldStatus) notifyListeners();
    }

    return moved;
  }

  bool _moveLeft() {
    bool moved = false;
    for (int row = 0; row < gridSize; row++) {
      final rowTiles = tiles.where((t) => t.row == row).toList()
        ..sort((a, b) => a.col.compareTo(b.col));
      moved = _mergeLine(rowTiles, true, false) || moved;
    }
    return moved;
  }

  bool _moveRight() {
    bool moved = false;
    for (int row = 0; row < gridSize; row++) {
      final rowTiles = tiles.where((t) => t.row == row).toList()
        ..sort((a, b) => b.col.compareTo(a.col));
      moved = _mergeLine(rowTiles, true, true) || moved;
    }
    return moved;
  }

  bool _moveUp() {
    bool moved = false;
    for (int col = 0; col < gridSize; col++) {
      final colTiles = tiles.where((t) => t.col == col).toList()
        ..sort((a, b) => a.row.compareTo(b.row));
      moved = _mergeLine(colTiles, false, false) || moved;
    }
    return moved;
  }

  bool _moveDown() {
    bool moved = false;
    for (int col = 0; col < gridSize; col++) {
      final colTiles = tiles.where((t) => t.col == col).toList()
        ..sort((a, b) => b.row.compareTo(a.row));
      moved = _mergeLine(colTiles, false, true) || moved;
    }
    return moved;
  }

  /// Compress and merge one row or column toward its destination edge.
  bool _mergeLine(List<Tile> lineTiles, bool isRow, bool reversed) {
    bool moved = false;
    final List<Tile> merged = [];
    int targetPos = reversed ? gridSize - 1 : 0;
    final int step = reversed ? -1 : 1;

    for (final tile in lineTiles) {
      if (merged.isNotEmpty) {
        final previous = merged.last;
        final previousPos = isRow ? previous.col : previous.row;
        if (previousPos == targetPos &&
            previous.value == tile.value &&
            !previous.merged) {
          previous.value *= 2;
          previous.merged = true;
          score += previous.value;
          tiles.remove(tile);
          moved = true;

          if (previous.value >= goal && !hasWon) {
            hasWon = true;
            status = GameStatus.won;
          }
          continue;
        }
        targetPos = previousPos + step;
      }

      final oldPos = isRow ? tile.col : tile.row;
      if (oldPos != targetPos) {
        if (isRow) {
          tile.col = targetPos;
        } else {
          tile.row = targetPos;
        }
        moved = true;
      }
      merged.add(tile);
    }

    return moved;
  }

  void _spawnTile() {
    final empty = _getEmptyCells();
    if (empty.isEmpty) return;

    final cell = empty[_random.nextInt(empty.length)];
    final value = _random.nextInt(10) < 9 ? 2 : 4;
    tiles.add(Tile(
      row: cell[0],
      col: cell[1],
      value: value,
      id: _nextTileId++,
      isNew: true,
    ));
  }

  List<List<int>> _getEmptyCells() {
    final occupied = <String>{};
    for (final tile in tiles) {
      occupied.add('${tile.row},${tile.col}');
    }

    final empty = <List<int>>[];
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (!occupied.contains('$row,$col')) empty.add([row, col]);
      }
    }
    return empty;
  }

  void _checkGameState() {
    // Preserve the win prompt until the player explicitly chooses Keep Going.
    if (status != GameStatus.playing || _getEmptyCells().isNotEmpty) return;

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final value = _valueAt(row, col);
        if (col < gridSize - 1 && value == _valueAt(row, col + 1)) return;
        if (row < gridSize - 1 && value == _valueAt(row + 1, col)) return;
      }
    }

    status = GameStatus.lost;
  }

  int _valueAt(int row, int col) {
    for (final tile in tiles) {
      if (tile.row == row && tile.col == col) return tile.value;
    }
    return 0;
  }

  void continueGame() {
    if (status != GameStatus.won) return;
    status = GameStatus.playing;
    _checkGameState();
    notifyListeners();
  }
}
