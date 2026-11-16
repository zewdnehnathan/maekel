import 'dart:math';

class CandyBlast {
  const CandyBlast({
    required this.row,
    required this.col,
    required this.colorIndex,
  });

  final int row;
  final int col;
  final int colorIndex;
}

/// Match-3 candy board (Candy Crush–style) with stepped cascade for FX.
class CandyCrushEngine {
  CandyCrushEngine({Random? random}) : _random = random ?? Random() {
    reset();
  }

  static const int rows = 8;
  static const int cols = 8;
  static const int candyTypes = 6;
  static const int startingMoves = 30;

  final Random _random;

  late List<List<int>> board;
  int score = 0;
  int movesLeft = startingMoves;
  int combo = 0;
  bool isGameOver = false;
  bool isPaused = false;
  bool isBusy = false;
  (int, int)? selected;
  List<CandyBlast> activeBlasts = const [];

  void reset() {
    score = 0;
    movesLeft = startingMoves;
    combo = 0;
    isGameOver = false;
    isPaused = false;
    isBusy = false;
    selected = null;
    activeBlasts = const [];
    board = List.generate(rows, (_) => List.filled(cols, 0));
    _fillWithoutMatches();
    if (!_hasAnyMove()) {
      _shuffleUntilPlayable();
    }
  }

  void togglePause() {
    if (isGameOver || isBusy) return;
    isPaused = !isPaused;
  }

  bool get canInteract => !isGameOver && !isPaused && !isBusy;

  /// Tap a cell: select / deselect / start a swap.
  /// Returns `true` when a match wave started and the UI should play explosions.
  bool tapCell(int r, int c) {
    if (!canInteract) return false;
    if (!_inBounds(r, c)) return false;

    final sel = selected;
    if (sel == null) {
      selected = (r, c);
      return false;
    }

    final (sr, sc) = sel;
    if (sr == r && sc == c) {
      selected = null;
      return false;
    }

    if (!_isAdjacent(sr, sc, r, c)) {
      selected = (r, c);
      return false;
    }

    selected = null;
    return swapCells(sr, sc, r, c);
  }

  /// Drag/swap API. Board is unchanged when this returns false (invalid or no match).
  bool swapCells(int r1, int c1, int r2, int c2) {
    if (!canInteract) return false;
    if (!_inBounds(r1, c1) || !_inBounds(r2, c2)) return false;
    if (!_isAdjacent(r1, c1, r2, c2)) return false;

    selected = null;
    _swap(r1, c1, r2, c2);
    final matches = _findMatches();
    if (matches.isEmpty) {
      _swap(r1, c1, r2, c2);
      return false;
    }

    movesLeft -= 1;
    combo = 0;
    isBusy = true;
    _armBlasts(matches);
    return true;
  }

  bool isAdjacent(int r1, int c1, int r2, int c2) =>
      _isAdjacent(r1, c1, r2, c2);

  /// After explosion FX: clear matched cells, collapse, refill.
  /// Returns `true` if another blast wave started.
  bool finishBlastWave() {
    if (!isBusy || activeBlasts.isEmpty) return false;

    for (final blast in activeBlasts) {
      board[blast.row][blast.col] = -1;
    }
    activeBlasts = const [];

    _collapse();
    _refill();

    final next = _findMatches();
    if (next.isNotEmpty) {
      _armBlasts(next);
      return true;
    }

    isBusy = false;
    if (!_hasAnyMove()) {
      _shuffleUntilPlayable();
    }
    if (movesLeft <= 0) {
      isGameOver = true;
      selected = null;
    }
    return false;
  }

  void _armBlasts(Set<(int, int)> matches) {
    combo += 1;
    final base = matches.length * 10;
    final bonus = combo > 1 ? (combo - 1) * 25 : 0;
    score += base + bonus;

    activeBlasts = [
      for (final (r, c) in matches)
        CandyBlast(row: r, col: c, colorIndex: board[r][c]),
    ];
  }

  void _collapse() {
    for (var c = 0; c < cols; c++) {
      var write = rows - 1;
      for (var r = rows - 1; r >= 0; r--) {
        if (board[r][c] >= 0) {
          board[write][c] = board[r][c];
          if (write != r) board[r][c] = -1;
          write -= 1;
        }
      }
      for (var r = write; r >= 0; r--) {
        board[r][c] = -1;
      }
    }
  }

  void _refill() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (board[r][c] < 0) {
          board[r][c] = _random.nextInt(candyTypes);
        }
      }
    }
  }

  Set<(int, int)> _findMatches() {
    final matched = <(int, int)>{};

    for (var r = 0; r < rows; r++) {
      var runStart = 0;
      for (var c = 1; c <= cols; c++) {
        final same = c < cols &&
            board[r][c] >= 0 &&
            board[r][c] == board[r][runStart];
        if (!same) {
          if (c - runStart >= 3 && board[r][runStart] >= 0) {
            for (var k = runStart; k < c; k++) {
              matched.add((r, k));
            }
          }
          runStart = c;
        }
      }
    }

    for (var c = 0; c < cols; c++) {
      var runStart = 0;
      for (var r = 1; r <= rows; r++) {
        final same = r < rows &&
            board[r][c] >= 0 &&
            board[r][c] == board[runStart][c];
        if (!same) {
          if (r - runStart >= 3 && board[runStart][c] >= 0) {
            for (var k = runStart; k < r; k++) {
              matched.add((k, c));
            }
          }
          runStart = r;
        }
      }
    }

    return matched;
  }

  void _fillWithoutMatches() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        late int color;
        do {
          color = _random.nextInt(candyTypes);
        } while (_wouldMatchAt(r, c, color));
        board[r][c] = color;
      }
    }
  }

  bool _wouldMatchAt(int r, int c, int color) {
    if (c >= 2 &&
        board[r][c - 1] == color &&
        board[r][c - 2] == color) {
      return true;
    }
    if (r >= 2 &&
        board[r - 1][c] == color &&
        board[r - 2][c] == color) {
      return true;
    }
    return false;
  }

  bool _hasAnyMove() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (c + 1 < cols) {
          _swap(r, c, r, c + 1);
          final hit = _findMatches().isNotEmpty;
          _swap(r, c, r, c + 1);
          if (hit) return true;
        }
        if (r + 1 < rows) {
          _swap(r, c, r + 1, c);
          final hit = _findMatches().isNotEmpty;
          _swap(r, c, r + 1, c);
          if (hit) return true;
        }
      }
    }
    return false;
  }

  void _shuffleUntilPlayable() {
    for (var attempt = 0; attempt < 40; attempt++) {
      final flat = <int>[];
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          flat.add(board[r][c]);
        }
      }
      flat.shuffle(_random);
      var i = 0;
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          board[r][c] = flat[i++];
        }
      }
      if (_findMatches().isEmpty && _hasAnyMove()) return;
    }
    _fillWithoutMatches();
  }

  void _swap(int r1, int c1, int r2, int c2) {
    final tmp = board[r1][c1];
    board[r1][c1] = board[r2][c2];
    board[r2][c2] = tmp;
  }

  bool _inBounds(int r, int c) =>
      r >= 0 && r < rows && c >= 0 && c < cols;

  bool _isAdjacent(int r1, int c1, int r2, int c2) {
    return (r1 == r2 && (c1 - c2).abs() == 1) ||
        (c1 == c2 && (r1 - r2).abs() == 1);
  }
}
