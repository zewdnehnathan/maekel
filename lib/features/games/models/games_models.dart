enum ArcadeGame { tetris, brickBreaker, candyCrush }

extension ArcadeGameApi on ArcadeGame {
  String get apiValue => switch (this) {
        ArcadeGame.tetris => 'tetris',
        ArcadeGame.brickBreaker => 'brickBreaker',
        ArcadeGame.candyCrush => 'candyCrush',
      };

  String get label => switch (this) {
        ArcadeGame.tetris => 'Tetris',
        ArcadeGame.brickBreaker => 'Brick Breaker',
        ArcadeGame.candyCrush => 'Candy Crush',
      };
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.score,
  });

  final int rank;
  final String userId;
  final String displayName;
  final int score;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      score: (json['score'] as num).toInt(),
    );
  }
}

class GamesProfile {
  const GamesProfile({
    required this.userId,
    required this.displayName,
    required this.city,
  });

  final String userId;
  final String displayName;
  final String city;

  factory GamesProfile.fromJson(Map<String, dynamic> json) {
    return GamesProfile(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      city: json['city'] as String,
    );
  }
}

class ScoreSubmitResult {
  const ScoreSubmitResult({
    required this.isNewBest,
    required this.personalBest,
    required this.previousBest,
    required this.leaderboard,
    this.profile,
  });

  final bool isNewBest;
  final int personalBest;
  final int previousBest;
  final List<LeaderboardEntry> leaderboard;
  final GamesProfile? profile;

  factory ScoreSubmitResult.fromJson(Map<String, dynamic> json) {
    return ScoreSubmitResult(
      isNewBest: json['isNewBest'] as bool? ?? false,
      personalBest: (json['personalBest'] as num).toInt(),
      previousBest: (json['previousBest'] as num?)?.toInt() ?? 0,
      profile: json['profile'] is Map<String, dynamic>
          ? GamesProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      leaderboard: ((json['leaderboard'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(LeaderboardEntry.fromJson)
          .toList(),
    );
  }
}
