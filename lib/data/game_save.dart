/// Full persistent game state for 2048.
class GameSave {
  int bestScore;
  Map<int, int> bestScoresByGoal;
  int currentScore;
  int goal;
  int completedGameCount;
  bool isDarkTheme;
  bool adsRemoved;

  /// Serialized board state for session restore.
  /// Flat list of 16 ints (4x4 grid, row-major). 0 = empty.
  List<int>? boardState;

  /// Persisted controller state. Stored as the enum name to keep the data
  /// layer independent from the game layer.
  String gameStatus;

  /// Whether the player has reached 2048 at least once in this session.
  bool hasWon;

  GameSave({
    this.bestScore = 0,
    Map<int, int>? bestScoresByGoal,
    this.currentScore = 0,
    this.goal = 2048,
    this.completedGameCount = 0,
    this.isDarkTheme = false,
    this.adsRemoved = false,
    this.boardState,
    this.gameStatus = 'playing',
    this.hasWon = false,
  }) : bestScoresByGoal = bestScoresByGoal ?? <int, int>{};
}
