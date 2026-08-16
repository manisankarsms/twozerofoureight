/// Represents a single tile on the 2048 board.
class Tile {
  int row;
  int col;
  int value;

  /// Unique ID for animation tracking.
  final int id;

  /// Whether this tile was just merged (for animation purposes).
  bool merged;

  /// Whether this tile is newly spawned (for animation purposes).
  bool isNew;

  Tile({
    required this.row,
    required this.col,
    required this.value,
    required this.id,
    this.merged = false,
    this.isNew = false,
  });

  Tile copyWith({
    int? row,
    int? col,
    int? value,
    int? id,
    bool? merged,
    bool? isNew,
  }) {
    return Tile(
      row: row ?? this.row,
      col: col ?? this.col,
      value: value ?? this.value,
      id: id ?? this.id,
      merged: merged ?? this.merged,
      isNew: isNew ?? this.isNew,
    );
  }
}
