import '../../../core/network/api_client.dart';
import '../models/games_models.dart';

class GamesApi {
  GamesApi(this._client);

  final ApiClient _client;

  Future<Map<ArcadeGame, List<LeaderboardEntry>>> fetchAddisTop3() async {
    final raw = await _client.get(
      '/v1/games/leaderboard',
      query: {'city': 'Addis Ababa', 'limit': '3'},
    ) as Map<String, dynamic>;

    List<LeaderboardEntry> parse(String key) {
      final list = (raw[key] as List?) ?? const [];
      return list
          .cast<Map<String, dynamic>>()
          .map(LeaderboardEntry.fromJson)
          .toList();
    }

    return {
      ArcadeGame.tetris: parse('tetris'),
      ArcadeGame.brickBreaker: parse('brickBreaker'),
      ArcadeGame.candyCrush: parse('candyCrush'),
      ArcadeGame.roadFighter: parse('roadFighter'),
    };
  }

  Future<GamesProfile?> fetchMyProfile() async {
    final raw =
        await _client.get('/v1/games/me', auth: true) as Map<String, dynamic>;
    final profile = raw['profile'];
    if (profile is Map<String, dynamic>) {
      return GamesProfile.fromJson(profile);
    }
    return null;
  }

  Future<GamesProfile> saveProfile(String displayName) async {
    final raw = await _client.put(
      '/v1/games/me/profile',
      auth: true,
      body: {
        'displayName': displayName,
        'city': 'Addis Ababa',
      },
    ) as Map<String, dynamic>;
    return GamesProfile.fromJson(raw);
  }

  Future<ScoreSubmitResult> submitScore({
    required ArcadeGame game,
    required int score,
    String? displayName,
  }) async {
    final raw = await _client.post(
      '/v1/games/scores',
      auth: true,
      body: {
        'game': game.apiValue,
        'score': score,
        'city': 'Addis Ababa',
        if (displayName != null && displayName.trim().isNotEmpty)
          'displayName': displayName.trim(),
      },
    ) as Map<String, dynamic>;
    return ScoreSubmitResult.fromJson(raw);
  }
}
