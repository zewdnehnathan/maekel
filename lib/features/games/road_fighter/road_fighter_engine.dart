import 'dart:math';
import 'dart:ui';

enum RoadCarKind { traffic, fuel }

enum RoadFighterSfxEvent { start, fuel, pass, crash, outOfFuel }

class RoadCar {
  RoadCar({
    required this.x,
    required this.y,
    required this.kind,
    required this.colorIndex,
    required this.lane,
    this.canSwitchLanes = false,
    this.switchCooldown = 1.0,
  }) : targetLane = lane;

  double x;
  double y;
  final RoadCarKind kind;
  final int colorIndex;
  int lane;
  int targetLane;
  final bool canSwitchLanes;

  bool alive = true;
  bool passedPlayer = false;
  double switchCooldown;
}

class RoadFighterEngine {
  RoadFighterEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  Size playSize = Size.zero;

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
  bool endedByFuel = false;

  final List<RoadCar> cars = [];
  final List<RoadFighterSfxEvent> sfxEvents = [];

  double _spawnTimer = 0;
  double _distanceAcc = 0;
  double _secondsSinceFuelSpawn = 0;
  double _runTime = 0;
  int _steer = 0;

  static const playerW = 28.0;
  static const playerH = 40.0;
  static const carW = 28.0;
  static const carH = 40.0;
  static const laneCount = 3;
  static const maxSpeed = 980.0;
  static const minSpeed = 210.0;
  static const steerSpeed = 260.0;
  static const fuelDrainPerSec = 2.9;
  static const fuelPickupAmount = 24.0;
  static const forceFuelEverySec = 16.0;

  /// 0 soft → 1 hard. Ramps with distance + time.
  double get difficulty {
    final fromDist = (distanceMeters / 420).clamp(0.0, 1.0);
    final fromTime = (_runTime / 55).clamp(0.0, 1.0);
    return (fromDist * 0.65 + fromTime * 0.35).clamp(0.0, 1.0);
  }

  /// HUD speed that keeps climbing with the run.
  int get displaySpeed => (speed * 0.18).round();

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
    endedByFuel = false;
    cars.clear();
    sfxEvents.clear();
    _spawnTimer = 0.55;
    _distanceAcc = 0;
    _secondsSinceFuelSpawn = 0;
    _runTime = 0;
    _steer = 0;
    _layoutPlayer();
  }

  void start() {
    if (isGameOver) return;
    if (isRunning) return;
    awaitingStart = false;
    isRunning = true;
    _spawnTimer = 0.35;
    sfxEvents.add(RoadFighterSfxEvent.start);
  }

  List<RoadFighterSfxEvent> takeSfxEvents() {
    if (sfxEvents.isEmpty) return const [];
    final copy = List<RoadFighterSfxEvent>.from(sfxEvents);
    sfxEvents.clear();
    return copy;
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

    _runTime += dt;
    final diff = difficulty;

    if (_steer != 0) {
      playerX += _steer * steerSpeed * (1.0 + diff * 0.15) * dt;
      _clampPlayer();
    }

    // Keep accelerating hard so SPD never feels capped early.
    final accel = 28 + diff * 55;
    speed = (speed + accel * dt).clamp(minSpeed, maxSpeed);
    scroll += speed * dt;

    _distanceAcc += speed * dt;
    while (_distanceAcc >= 10) {
      _distanceAcc -= 10;
      distanceMeters += 1;
      score += 1 + (diff * 2).round();
    }

    // Tighter fuel economy — must hunt F cars.
    fuel -= fuelDrainPerSec * dt * (0.95 + diff * 0.55 + speed / maxSpeed * 0.35);
    if (fuel <= 0) {
      fuel = 0;
      _crash(outOfFuel: true);
      return;
    }

    _secondsSinceFuelSpawn += dt;

    _updateTraffic(dt, diff);
    cars.removeWhere((c) => !c.alive);

    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnCar(diff);
      final gap = (0.95 - diff * 0.55).clamp(0.28, 0.95);
      _spawnTimer = gap + _random.nextDouble() * (0.22 - diff * 0.08);
    }

    final p = playerRect.deflate(3);
    for (final c in cars) {
      if (!c.alive) continue;
      final r = carRect(c).deflate(2);
      if (!p.overlaps(r)) continue;
      if (c.kind == RoadCarKind.fuel) {
        c.alive = false;
        fuel = (fuel + fuelPickupAmount).clamp(0, 100);
        score += 50;
        sfxEvents.add(RoadFighterSfxEvent.fuel);
      } else {
        _crash(outOfFuel: false);
        return;
      }
    }
  }

  void _updateTraffic(double dt, double diff) {
    final laneSlide = 140 + diff * 120;
    for (final c in cars) {
      if (!c.alive) continue;

      final approach = c.kind == RoadCarKind.fuel
          ? speed * (0.52 + diff * 0.08)
          : speed * (0.68 + diff * 0.18);
      c.y += approach * dt;

      if (c.canSwitchLanes && c.kind == RoadCarKind.traffic) {
        c.switchCooldown -= dt;
        if (c.switchCooldown <= 0 && c.lane == c.targetLane) {
          _pickNewLane(c, diff);
        }
        final targetX = laneCenterX(c.targetLane);
        final dx = targetX - c.x;
        if (dx.abs() < 1.5) {
          c.x = targetX;
          c.lane = c.targetLane;
        } else {
          c.x += dx.sign * laneSlide * dt;
          // Update logical lane when past midpoint.
          final mid = (laneCenterX(c.lane) + targetX) / 2;
          if ((c.x - mid).abs() < laneWidth * 0.2) {
            c.lane = c.targetLane;
          }
        }
      }

      if (!c.passedPlayer &&
          c.kind == RoadCarKind.traffic &&
          c.y > playerY + playerH * 0.35) {
        c.passedPlayer = true;
        score += 15 + (diff * 20).round();
        sfxEvents.add(RoadFighterSfxEvent.pass);
      }
      if (c.y > playSize.height + 60) {
        c.alive = false;
      }
    }
  }

  void _pickNewLane(RoadCar c, double diff) {
    // Prefer cutting toward the player's lane as difficulty rises.
    final playerLane = ((playerX - roadLeft) / laneWidth).floor().clamp(
          0,
          laneCount - 1,
        );
    final options = <int>[
      for (var i = 0; i < laneCount; i++)
        if (i != c.lane) i,
    ];
    if (options.isEmpty) return;

    int next;
    if (_random.nextDouble() < 0.35 + diff * 0.45) {
      next = options.contains(playerLane)
          ? playerLane
          : options[_random.nextInt(options.length)];
    } else {
      next = options[_random.nextInt(options.length)];
    }

    // Don't pile into another car already in that lane nearby.
    final blocked = cars.any(
      (o) =>
          o.alive &&
          o != c &&
          o.lane == next &&
          (o.y - c.y).abs() < carH * 2.2,
    );
    if (blocked) {
      c.switchCooldown = 0.4 + _random.nextDouble() * 0.5;
      return;
    }

    c.targetLane = next;
    c.switchCooldown = (1.4 - diff * 0.7).clamp(0.45, 1.4) +
        _random.nextDouble() * 0.6;
  }

  void _spawnCar(double diff) {
    if (playSize == Size.zero) return;

    final occupied = <int>{};
    for (final c in cars) {
      if (c.y < 150) occupied.add(c.lane);
    }

    final free = <int>[
      for (var i = 0; i < laneCount; i++)
        if (!occupied.contains(i)) i,
    ];
    if (free.isEmpty) return;

    final lane = free[_random.nextInt(free.length)];
    final veryLow = fuel < 28;
    final forceFuel =
        veryLow && _secondsSinceFuelSpawn >= forceFuelEverySec * 0.65;
    final overdue = _secondsSinceFuelSpawn >= forceFuelEverySec && fuel < 50;
    final fuelChance = 0.08 + (fuel < 40 ? 0.08 : 0.0);
    final isFuel = forceFuel || overdue || _random.nextDouble() < fuelChance;
    if (isFuel) {
      _secondsSinceFuelSpawn = 0;
    }

    // Lane-switchers unlock mid-run and become common later.
    final switchChance = isFuel ? 0.0 : (diff < 0.18 ? 0.0 : 0.25 + diff * 0.55);

    cars.add(
      RoadCar(
        x: laneCenterX(lane),
        y: -carH - _random.nextDouble() * 40,
        kind: isFuel ? RoadCarKind.fuel : RoadCarKind.traffic,
        colorIndex: isFuel ? 0 : _random.nextInt(4),
        lane: lane,
        canSwitchLanes: !isFuel && _random.nextDouble() < switchChance,
        switchCooldown: 0.7 + _random.nextDouble() * 1.1,
      ),
    );

    // Extra traffic pack as difficulty rises.
    final packChance = 0.22 + diff * 0.45;
    if (!isFuel && free.length > 1 && _random.nextDouble() < packChance) {
      final other = free.where((l) => l != lane).toList();
      final lane2 = other[_random.nextInt(other.length)];
      cars.add(
        RoadCar(
          x: laneCenterX(lane2),
          y: -carH - 55 - _random.nextDouble() * 70,
          kind: RoadCarKind.traffic,
          colorIndex: _random.nextInt(4),
          lane: lane2,
          canSwitchLanes:
              diff > 0.35 && _random.nextDouble() < 0.4 + diff * 0.4,
          switchCooldown: 0.5 + _random.nextDouble() * 0.9,
        ),
      );
    }
  }

  void _crash({required bool outOfFuel}) {
    isRunning = false;
    isGameOver = true;
    awaitingStart = false;
    endedByFuel = outOfFuel;
    sfxEvents.add(
      outOfFuel ? RoadFighterSfxEvent.outOfFuel : RoadFighterSfxEvent.crash,
    );
  }
}
