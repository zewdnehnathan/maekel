import 'dart:math';
import 'dart:ui';

enum RoadCarKind { traffic, fuel }

class RoadCar {
  RoadCar({
    required this.x,
    required this.y,
    required this.kind,
    required this.colorIndex,
    required this.lane,
  });

  double x;
  double y;
  final RoadCarKind kind;
  final int colorIndex;
  final int lane;

  bool alive = true;
}

class RoadFighterEngine {
  RoadFighterEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  Size playSize = Size.zero;

  /// World units: player sits near bottom; world scrolls downward on screen.
  double playerX = 0;
  double playerY = 0;
  double scroll = 0;
  double speed = 220;
  double fuel = 100;
  int score = 0;
  int distanceMeters = 0;
  bool isRunning = false;
  bool isGameOver = false;
  bool awaitingStart = true;

  final List<RoadCar> cars = [];

  double _spawnTimer = 0;
  double _distanceAcc = 0;
  int _steer = 0; // -1 left, 0 none, 1 right

  static const playerW = 28.0;
  static const playerH = 40.0;
  static const carW = 28.0;
  static const carH = 40.0;
  static const laneCount = 3;
  static const maxSpeed = 520.0;
  static const minSpeed = 180.0;
  static const steerSpeed = 210.0;
  static const fuelDrainPerSec = 4.2;

  double get roadLeft => playSize.width * 0.22;
  double get roadRight => playSize.width * 0.78;
  double get roadWidth => roadRight - roadLeft;
  double get laneWidth => roadWidth / laneCount;

  double laneCenterX(int lane) {
    final clamped = lane.clamp(0, laneCount - 1);
    return roadLeft + laneWidth * (clamped + 0.5);
  }

  void configure(Size size) {
    if (size == Size.zero) return;
    final same = (playSize.width - size.width).abs() < 0.5 &&
        (playSize.height - size.height).abs() < 0.5;
    playSize = size;
    if (!same || awaitingStart && cars.isEmpty) {
      _layoutPlayer();
      if (!isRunning && !isGameOver) {
        cars.clear();
      }
    } else {
      _clampPlayer();
    }
  }

  void reset() {
    score = 0;
    distanceMeters = 0;
    fuel = 100;
    speed = minSpeed;
    scroll = 0;
    isGameOver = false;
    isRunning = false;
    awaitingStart = true;
    cars.clear();
    _spawnTimer = 0.6;
    _distanceAcc = 0;
    _steer = 0;
    _layoutPlayer();
  }

  void start() {
    if (isGameOver) return;
    if (isRunning) return;
    awaitingStart = false;
    isRunning = true;
    _spawnTimer = 0.4;
  }

  void setSteer(int dir) {
    _steer = dir.clamp(-1, 1);
  }

  void movePlayerTo(double x) {
    if (!isRunning || isGameOver) return;
    playerX = x;
    _clampPlayer();
  }

  void _layoutPlayer() {
    if (playSize == Size.zero) return;
    playerX = laneCenterX(1);
    playerY = playSize.height * 0.78;
  }

  void _clampPlayer() {
    final half = playerW / 2;
    playerX = playerX.clamp(roadLeft + half + 2, roadRight - half - 2);
  }

  Rect get playerRect => Rect.fromCenter(
        center: Offset(playerX, playerY),
        width: playerW,
        height: playerH,
      );

  Rect carRect(RoadCar c) => Rect.fromCenter(
        center: Offset(c.x, c.y),
        width: carW,
        height: carH,
      );

  void update(double dt) {
    if (!isRunning || isGameOver || playSize == Size.zero) return;

    // Steer
    if (_steer != 0) {
      playerX += _steer * steerSpeed * dt;
      _clampPlayer();
    }

    // Accelerate gradually
    speed = (speed + 12 * dt).clamp(minSpeed, maxSpeed);
    scroll += speed * dt;

    // Distance / score
    _distanceAcc += speed * dt;
    while (_distanceAcc >= 10) {
      _distanceAcc -= 10;
      distanceMeters += 1;
      score += 1;
    }

    // Fuel
    fuel -= fuelDrainPerSec * dt * (0.7 + speed / maxSpeed * 0.5);
    if (fuel <= 0) {
      fuel = 0;
      _crash(outOfFuel: true);
      return;
    }

    // Move traffic toward player (down the screen)
    for (final c in cars) {
      if (!c.alive) continue;
      final relative = c.kind == RoadCarKind.fuel ? speed * 0.55 : speed * 0.72;
      c.y += relative * dt;
      if (c.y > playSize.height + 60) {
        c.alive = false;
        if (c.kind == RoadCarKind.traffic) {
          score += 15;
        }
      }
    }
    cars.removeWhere((c) => !c.alive);

    // Spawns
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnCar();
      final gap = (1.15 - (speed - minSpeed) / (maxSpeed - minSpeed) * 0.55)
          .clamp(0.45, 1.2);
      _spawnTimer = gap + _random.nextDouble() * 0.35;
    }

    // Collisions
    final p = playerRect.deflate(4);
    for (final c in cars) {
      if (!c.alive) continue;
      final r = carRect(c).deflate(3);
      if (!p.overlaps(r)) continue;
      if (c.kind == RoadCarKind.fuel) {
        c.alive = false;
        fuel = (fuel + 28).clamp(0, 100);
        score += 50;
      } else {
        _crash(outOfFuel: false);
        return;
      }
    }

    // Soft shoulder crash if shoved hard into edge (optional feel)
    if (playerX <= roadLeft + playerW / 2 + 1 ||
        playerX >= roadRight - playerW / 2 - 1) {
      // grazing ok; only crash if pressed into barrier
    }
  }

  void _spawnCar() {
    if (playSize == Size.zero) return;

    // Avoid stacking on the same lane too tightly near spawn.
    final occupied = <int>{};
    for (final c in cars) {
      if (c.y < 140) occupied.add(c.lane);
    }

    final free = <int>[
      for (var i = 0; i < laneCount; i++)
        if (!occupied.contains(i)) i,
    ];
    if (free.isEmpty) return;

    final lane = free[_random.nextInt(free.length)];
    final isFuel = _random.nextDouble() < 0.14;
    cars.add(
      RoadCar(
        x: laneCenterX(lane),
        y: -carH - _random.nextDouble() * 40,
        kind: isFuel ? RoadCarKind.fuel : RoadCarKind.traffic,
        colorIndex: isFuel ? 0 : _random.nextInt(4),
        lane: lane,
      ),
    );

    // Sometimes spawn a second traffic car in another free lane.
    if (!isFuel && free.length > 1 && _random.nextDouble() < 0.28) {
      final other = free.where((l) => l != lane).toList();
      final lane2 = other[_random.nextInt(other.length)];
      cars.add(
        RoadCar(
          x: laneCenterX(lane2),
          y: -carH - 70 - _random.nextDouble() * 50,
          kind: RoadCarKind.traffic,
          colorIndex: _random.nextInt(4),
          lane: lane2,
        ),
      );
    }
  }

  void _crash({required bool outOfFuel}) {
    isRunning = false;
    isGameOver = true;
    awaitingStart = false;
    // Keep score as-is for leaderboard submit.
    if (outOfFuel && score < distanceMeters) {
      // no-op; score already tracks distance
    }
  }
}
