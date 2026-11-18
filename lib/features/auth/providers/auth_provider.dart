import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/network/token_store.dart';
import '../../food/services/api_food_repository.dart';
import '../../market/services/api_market_repository.dart';
import '../../ride/services/api_ride_repository.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.phoneE164,
    required this.accessToken,
    this.roles = const [],
  });

  final String userId;
  final String phoneE164;
  final String accessToken;
  final List<String> roles;

  bool get isPlatformAdmin => roles.contains('platform_admin');

  bool get isMarketModerator =>
      isPlatformAdmin ||
      roles.contains('market_moderator') ||
      roles.contains('market_ops');
}

class AuthState {
  const AuthState({
    this.session,
    this.pendingPhoneE164,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final AuthSession? session;
  final String? pendingPhoneE164;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    AuthSession? session,
    String? pendingPhoneE164,
    bool? isSubmitting,
    String? errorMessage,
    bool clearSession = false,
    bool clearPendingPhone = false,
    bool clearError = false,
  }) {
    return AuthState(
      session: clearSession ? null : (session ?? this.session),
      pendingPhoneE164: clearPendingPhone
          ? null
          : (pendingPhoneE164 ?? this.pendingPhoneE164),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  TokenStore get _tokens => ref.read(tokenStoreProvider);
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  AuthState build() => const AuthState();

  Future<bool> submitPhone(String localDigits) async {
    final cleaned = localDigits.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != AppConstants.localPhoneLength) {
      state = state.copyWith(
        errorMessage:
            'Enter a ${AppConstants.localPhoneLength}-digit local number.',
        clearError: false,
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    final e164 = '${AppConstants.phoneCountryCode}$cleaned';
    try {
      await _api.post('/v1/auth/otp/request', body: {'phone': e164});
      state = state.copyWith(
        pendingPhoneE164: e164,
        isSubmitting: false,
        clearError: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            'Could not reach Maekel API at ${AppConstants.apiBaseUrl}',
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    final pending = state.pendingPhoneE164;
    if (pending == null) {
      state = state.copyWith(errorMessage: 'Start again with your phone number.');
      return false;
    }

    final cleaned = code.replaceAll(RegExp(r'\D'), '');
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final raw = await _api.post(
        '/v1/auth/otp/verify',
        body: {'phone': pending, 'code': cleaned},
      ) as Map<String, dynamic>;

      final accessToken = raw['accessToken'] as String;
      final userId = raw['userId'] as String;
      final phone = (raw['phone'] as String?) ?? pending;
      final roles = ((raw['roles'] as List?) ?? const [])
          .map((e) => '$e')
          .toList();

      _tokens.setAccessToken(accessToken);
      state = AuthState(
        session: AuthSession(
          userId: userId,
          phoneE164: phone,
          accessToken: accessToken,
          roles: roles,
        ),
      );

      await _hydrateRepos(userId);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not verify OTP. Is the gateway running?',
      );
      return false;
    }
  }

  Future<void> _hydrateRepos(String userId) async {
    final market = ref.read(marketRepositoryProvider);
    final food = ref.read(foodRepositoryProvider);
    final ride = ref.read(rideRepositoryProvider);
    if (market is ApiMarketRepository) {
      await market.refreshAuthed(userId);
    }
    if (food is ApiFoodRepository) {
      await food.refreshAuthed();
    }
    if (ride is ApiRideRepository) {
      await ride.refreshAuthed(userId);
    }
  }

  void signOut() {
    _tokens.clear();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
