import 'dart:math';
import 'dart:ui';

class Brick {
  Brick({
    required this.rect,
    required this.hits,
    required this.colorIndex,
  });

  Rect rect;
  int hits;
  final int colorIndex;

  bool get isAlive => hits > 0;
}

class BrickBreakerEngine {
  BrickBreakerEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  Size playSize = Size.zero;
  Rect paddle = Rect.zero;
  Offset ball = Offset.zero;
  Offset velocity = Offset.zero;
  List<Brick> bricks = [];

  int score = 0;
  int lives = 3;
  int level = 1;
  bool isRunning = false;
  bool isGameOver = false;
  bool isWon = false;
  bool ballLaunched = false;

  static const paddleWidthFactor = 0.22;
  static const paddleHeight = 14.0;
  static const ballRadius = 8.0;

  void configure(Size size) {
    if (size == Size.zero) return;
    final same = (playSize.width - size.width).abs() < 0.5 &&
        (playSize.height - size.height).abs() < 0.5;
    playSize = size;
    if (!same || bricks.isEmpty) {
      _resetLevel(keepScore: score > 0 && !isGameOver);
    } else {
      _clampPaddle();
    }
  }

  void reset() {
    score = 0;
    lives = 3;
    level = 1;
    isGameOver = false;
    isWon = false;
    isRunning = false;
    _resetLevel(keepScore: false);
  }

  void _resetLevel({required bool keepScore}) {
    if (!keepScore) score = 0;
    final w = playSize.width;
    final h = playSize.height;
    if (w <= 0 || h <= 0) {
      bricks = [];
      paddle = Rect.zero;
      ball = Offset.zero;
      velocity = Offset.zero;
      return;
    }

    final paddleW = w * paddleWidthFactor;
    paddle = Rect.fromCenter(
      center: Offset(w / 2, h - 36),
      width: paddleW,
      height: paddleHeight,
    );
    _parkBall();
    ballLaunched = false;
    isRunning = false;
    isWon = false;

    final cols = 7;
    final rows = 4 + (level - 1).clamp(0, 3);
    final gap = 6.0;
    final top = 48.0;
    final side = 12.0;
    final brickW = (w - side * 2 - gap * (cols - 1)) / cols;
    final brickH = 18.0;
    bricks = [];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final left = side + c * (brickW + gap);
        final topY = top + r * (brickH + gap);
        bricks.add(
          Brick(
            rect: Rect.fromLTWH(left, topY, brickW, brickH),
            hits: 1 + (r == 0 ? 1 : 0),
            colorIndex: r % 4,
          ),
        );
      }
    }
  }

  void _parkBall() {
    ball = Offset(paddle.center.dx, paddle.top - ballRadius - 2);
    velocity = Offset.zero;
  }

  void _clampPaddle() {
    final half = paddle.width / 2;
    final cx = paddle.center.dx.clamp(half, playSize.width - half);
    paddle = Rect.fromCenter(
      center: Offset(cx, paddle.center.dy),
      width: paddle.width,
      height: paddle.height,
    );
    if (!ballLaunched) _parkBall();
  }

  void movePaddleTo(double x) {
    final half = paddle.width / 2;
    final cx = x.clamp(half, playSize.width - half);
    paddle = Rect.fromCenter(
      center: Offset(cx, paddle.center.dy),
      width: paddle.width,
      height: paddle.height,
    );
    if (!ballLaunched) _parkBall();
  }

  void launch() {
    if (isGameOver || isWon || ballLaunched) return;
    ballLaunched = true;
    isRunning = true;
    final speed = 320 + level * 28.0;
    final angle = (-pi / 2) + (_random.nextDouble() - 0.5) * 0.9;
    velocity = Offset(cos(angle) * speed, sin(angle) * speed);
  }

  void update(double dt) {
    if (!isRunning || isGameOver || isWon || !ballLaunched) return;

    var next = ball + velocity * dt;

    // Walls
    if (next.dx - ballRadius <= 0) {
      next = Offset(ballRadius, next.dy);
      velocity = Offset(velocity.dx.abs(), velocity.dy);
    } else if (next.dx + ballRadius >= playSize.width) {
      next = Offset(playSize.width - ballRadius, next.dy);
      velocity = Offset(-velocity.dx.abs(), velocity.dy);
    }
    if (next.dy - ballRadius <= 0) {
      next = Offset(next.dx, ballRadius);
      velocity = Offset(velocity.dx, velocity.dy.abs());
    }

    // Paddle
    final ballRect = Rect.fromCircle(center: next, radius: ballRadius);
    if (velocity.dy > 0 && ballRect.overlaps(paddle)) {
      final hit = ((next.dx - paddle.left) / paddle.width).clamp(0.0, 1.0);
      final angle = -pi * 0.75 + hit * (pi * 0.5);
      final speed = velocity.distance.clamp(280.0, 520.0);
      velocity = Offset(cos(angle) * speed, sin(angle) * speed);
      next = Offset(next.dx, paddle.top - ballRadius - 0.5);
    }

    // Bricks
    for (final brick in bricks) {
      if (!brick.isAlive) continue;
      if (!ballRect.overlaps(brick.rect)) continue;
      brick.hits -= 1;
      if (!brick.isAlive) score += 10 * level;

      final overlapL = (ballRect.right - brick.rect.left).abs();
      final overlapR = (brick.rect.right - ballRect.left).abs();
      final overlapT = (ballRect.bottom - brick.rect.top).abs();
      final overlapB = (brick.rect.bottom - ballRect.top).abs();
      final minH = min(overlapL, overlapR);
      final minV = min(overlapT, overlapB);
      if (minH < minV) {
        velocity = Offset(-velocity.dx, velocity.dy);
      } else {
        velocity = Offset(velocity.dx, -velocity.dy);
      }
      break;
    }

    // Lost ball
    if (next.dy - ballRadius > playSize.height) {
      lives -= 1;
      ballLaunched = false;
      isRunning = false;
      _parkBall();
      if (lives <= 0) {
        isGameOver = true;
      }
      ball = next;
      return;
    }

    ball = next;

    if (bricks.every((b) => !b.isAlive)) {
      level += 1;
      isWon = false;
      _resetLevel(keepScore: true);
    }
  }
}
