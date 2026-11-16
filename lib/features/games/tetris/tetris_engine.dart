import 'dart:math';

enum Tetromino { i, o, t, s, z, j, l }

class Cell {
  const Cell(this.x, this.y);
  final int x;
  final int y;
}

class Piece {
  Piece({
    required this.type,
    required this.rotation,
    required this.originX,
    required this.originY,
  });

  final Tetromino type;
  final int rotation;
  final int originX;
  final int originY;

  Piece copyWith({int? rotation, int? originX, int? originY}) {
    return Piece(
      type: type,
      rotation: rotation ?? this.rotation,
      originX: originX ?? this.originX,
      originY: originY ?? this.originY,
    );
  }

  List<Cell> cells() {
    final shape = _shapes[type]![rotation % _shapes[type]!.length];
    return [
      for (final c in shape) Cell(originX + c.x, originY + c.y),
    ];
  }
}

const _shapes = <Tetromino, List<List<Cell>>>{
  Tetromino.i: [
    [Cell(0, 1), Cell(1, 1), Cell(2, 1), Cell(3, 1)],
    [Cell(2, 0), Cell(2, 1), Cell(2, 2), Cell(2, 3)],
  ],
  Tetromino.o: [
    [Cell(1, 0), Cell(2, 0), Cell(1, 1), Cell(2, 1)],
  ],
  Tetromino.t: [
    [Cell(1, 0), Cell(0, 1), Cell(1, 1), Cell(2, 1)],
    [Cell(1, 0), Cell(1, 1), Cell(2, 1), Cell(1, 2)],
    [Cell(0, 1), Cell(1, 1), Cell(2, 1), Cell(1, 2)],
    [Cell(1, 0), Cell(0, 1), Cell(1, 1), Cell(1, 2)],
  ],
  Tetromino.s: [
    [Cell(1, 0), Cell(2, 0), Cell(0, 1), Cell(1, 1)],
    [Cell(1, 0), Cell(1, 1), Cell(2, 1), Cell(2, 2)],
  ],
  Tetromino.z: [
    [Cell(0, 0), Cell(1, 0), Cell(1, 1), Cell(2, 1)],
    [Cell(2, 0), Cell(1, 1), Cell(2, 1), Cell(1, 2)],
  ],
  Tetromino.j: [
    [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(2, 1)],
    [Cell(1, 0), Cell(2, 0), Cell(1, 1), Cell(1, 2)],
    [Cell(0, 1), Cell(1, 1), Cell(2, 1), Cell(2, 2)],
    [Cell(1, 0), Cell(1, 1), Cell(0, 2), Cell(1, 2)],
  ],
  Tetromino.l: [
    [Cell(2, 0), Cell(0, 1), Cell(1, 1), Cell(2, 1)],
    [Cell(1, 0), Cell(1, 1), Cell(1, 2), Cell(2, 2)],
    [Cell(0, 1), Cell(1, 1), Cell(2, 1), Cell(0, 2)],
    [Cell(0, 0), Cell(1, 0), Cell(1, 1), Cell(1, 2)],
  ],
};

class TetrisEngine {
  TetrisEngine({this.columns = 10, this.rows = 20, Random? random})
      : _random = random ?? Random() {
    reset();
  }

  final int columns;
  final int rows;
  final Random _random;

  late List<List<Tetromino?>> grid;
  Piece? active;
  Tetromino? next;
  int score = 0;
  int lines = 0;
  int level = 1;
  bool isGameOver = false;
  bool isPaused = false;

  Duration get tickInterval {
    final ms = max(120, 700 - (level - 1) * 55);
    return Duration(milliseconds: ms);
  }

  void reset() {
    grid = List.generate(rows, (_) => List<Tetromino?>.filled(columns, null));
    score = 0;
    lines = 0;
    level = 1;
    isGameOver = false;
    isPaused = false;
    next = _randomType();
    _spawn();
  }

  void togglePause() {
    if (!isGameOver) isPaused = !isPaused;
  }

  bool tick() {
    if (isGameOver || isPaused) return false;
    return softDrop();
  }

  bool moveLeft() => _shift(-1, 0);
  bool moveRight() => _shift(1, 0);

  bool softDrop() {
    if (!_shift(0, 1)) {
      _lock();
      return false;
    }
    return true;
  }

  void hardDrop() {
    if (active == null || isGameOver || isPaused) return;
    while (_shift(0, 1)) {
      score += 2;
    }
    _lock();
  }

  void rotate() {
    if (active == null || isGameOver || isPaused) return;
    final shapes = _shapes[active!.type]!;
    final nextRot = (active!.rotation + 1) % shapes.length;
    final kicked = [
      active!.copyWith(rotation: nextRot),
      active!.copyWith(rotation: nextRot, originX: active!.originX - 1),
      active!.copyWith(rotation: nextRot, originX: active!.originX + 1),
      active!.copyWith(rotation: nextRot, originX: active!.originX - 2),
      active!.copyWith(rotation: nextRot, originX: active!.originX + 2),
    ];
    for (final candidate in kicked) {
      if (_fits(candidate)) {
        active = candidate;
        return;
      }
    }
  }

  bool _shift(int dx, int dy) {
    if (active == null || isGameOver || isPaused) return false;
    final moved = active!.copyWith(
      originX: active!.originX + dx,
      originY: active!.originY + dy,
    );
    if (!_fits(moved)) return false;
    active = moved;
    return true;
  }

  void _lock() {
    if (active == null) return;
    for (final c in active!.cells()) {
      if (c.y < 0 || c.y >= rows || c.x < 0 || c.x >= columns) {
        isGameOver = true;
        active = null;
        return;
      }
      grid[c.y][c.x] = active!.type;
    }
    _clearLines();
    _spawn();
  }

  void _clearLines() {
    var cleared = 0;
    for (var y = rows - 1; y >= 0; y--) {
      if (grid[y].every((cell) => cell != null)) {
        grid.removeAt(y);
        grid.insert(0, List<Tetromino?>.filled(columns, null));
        cleared += 1;
        y += 1;
      }
    }
    if (cleared == 0) return;
    lines += cleared;
    level = 1 + lines ~/ 10;
    const scores = [0, 100, 300, 500, 800];
    score += scores[cleared] * level;
  }

  void _spawn() {
    final type = next ?? _randomType();
    next = _randomType();
    active = Piece(type: type, rotation: 0, originX: 3, originY: -1);
    if (!_fits(active!)) {
      isGameOver = true;
      active = null;
    }
  }

  bool _fits(Piece piece) {
    for (final c in piece.cells()) {
      if (c.x < 0 || c.x >= columns || c.y >= rows) return false;
      if (c.y < 0) continue;
      if (grid[c.y][c.x] != null) return false;
    }
    return true;
  }

  Tetromino _randomType() {
    const values = Tetromino.values;
    return values[_random.nextInt(values.length)];
  }
}
