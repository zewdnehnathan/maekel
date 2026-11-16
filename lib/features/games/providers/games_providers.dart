import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../models/games_models.dart';
import '../services/games_api.dart';

final gamesApiProvider = Provider<GamesApi>((ref) {
  return GamesApi(ref.watch(apiClientProvider));
});

final addisLeaderboardProvider =
    FutureProvider<Map<ArcadeGame, List<LeaderboardEntry>>>((ref) async {
  return ref.watch(gamesApiProvider).fetchAddisTop3();
});

final gamesProfileProvider = FutureProvider<GamesProfile?>((ref) async {
  try {
    return await ref.watch(gamesApiProvider).fetchMyProfile();
  } catch (_) {
    return null;
  }
});
