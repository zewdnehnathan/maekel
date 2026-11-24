import '../../l10n/app_localizations.dart';
import '../constants/app_constants.dart';

const authErrorPhoneDigits = 'phone_digits';
const authErrorStartAgain = 'start_again';
const authErrorApiUnreachable = 'api_unreachable';
const authErrorOtpGateway = 'otp_gateway';

String resolveAuthErrorMessage(AppLocalizations l10n, String? message) {
  if (message == null) return '';
  return switch (message) {
    authErrorPhoneDigits =>
      l10n.adminPhoneDigits(AppConstants.localPhoneLength),
    authErrorStartAgain => l10n.authStartAgain,
    authErrorApiUnreachable => l10n.authApiUnreachable(AppConstants.apiBaseUrl),
    authErrorOtpGateway => l10n.authOtpGateway,
    _ => message,
  };
}

String localizedAdminRole(AppLocalizations l10n, String role) {
  return switch (role) {
    'platform_admin' => l10n.adminPlatformAdmin,
    'market_moderator' => l10n.adminMarketModerator,
    'market_ops' => l10n.adminMarketOps,
    'food_ops' => l10n.adminFoodOps,
    'food_merchant' => l10n.adminFoodMerchant,
    'food_rider' => l10n.adminFoodRider,
    'ride_ops' => l10n.adminRideOps,
    'events_ops' => l10n.adminEventsOps,
    _ => role,
  };
}