import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/admin/screens/admin_staff_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/phone_screen.dart';
import '../features/food/screens/food_cart_screen.dart';
import '../features/food/screens/food_checkout_screen.dart';
import '../features/food/screens/food_merchant_console_screen.dart';
import '../features/food/screens/food_merchant_screen.dart';
import '../features/food/screens/food_ops_screen.dart';
import '../features/food/screens/food_order_detail_screen.dart';
import '../features/food/screens/food_orders_screen.dart';
import '../features/food/screens/food_rider_screen.dart';
import '../features/food/screens/food_screen.dart';
import '../features/games/screens/brick_breaker_screen.dart';
import '../features/games/screens/candy_crush_screen.dart';
import '../features/games/screens/games_hub_screen.dart';
import '../features/games/screens/road_fighter_screen.dart';
import '../features/games/screens/tetris_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/market/screens/market_ad_detail_screen.dart';
import '../features/market/screens/market_category_screen.dart';
import '../features/market/screens/market_chat_screen.dart';
import '../features/market/screens/market_favorites_screen.dart';
import '../features/market/screens/market_messages_screen.dart';
import '../features/market/screens/market_my_ads_screen.dart';
import '../features/market/screens/market_ops_screen.dart';
import '../features/market/screens/market_screen.dart';
import '../features/market/screens/market_sell_screen.dart';
import '../features/ride/screens/ride_driver_screen.dart';
import '../features/ride/screens/ride_history_screen.dart';
import '../features/ride/screens/ride_screen.dart';
import '../features/ride/screens/ride_trip_screen.dart';

abstract final class AppRoutes {
  static const auth = '/auth';
  static const otp = '/auth/otp';
  static const home = '/home';

  static const ride = '/ride';
  static const rideDriver = '/ride/driver';
  static const rideHistory = '/ride/history';
  static const rideTrips = '/ride/trips';
  static const rideRequest = '/ride/request';

  static const market = '/market';
  static const marketSell = '/market/sell';
  static const marketMyAds = '/market/my-ads';
  static const marketFavorites = '/market/favorites';
  static const marketMessages = '/market/messages';
  static const marketOps = '/market/ops';
  static const adminStaff = '/admin/staff';

  static const food = '/food';
  static const foodCart = '/food/cart';
  static const foodCheckout = '/food/checkout';
  static const foodOrders = '/food/orders';
  static const foodMerchantConsole = '/food/console';
  static const foodRider = '/food/rider';
  static const foodOps = '/food/ops';

  static const games = '/games';
  static const brickBreaker = '/games/brick-breaker';
  static const tetris = '/games/tetris';
  static const candyCrush = '/games/candy-crush';
  static const roadFighter = '/games/road-fighter';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = _AuthRefresh(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isAuthed = auth.isAuthenticated;
      final loc = state.matchedLocation;
      final onAuthFlow = loc == AppRoutes.auth || loc == AppRoutes.otp;

      if (!isAuthed && !onAuthFlow) {
        return AppRoutes.auth;
      }
      if (isAuthed && onAuthFlow) {
        return AppRoutes.home;
      }
      if (!isAuthed &&
          loc == AppRoutes.otp &&
          auth.pendingPhoneE164 == null) {
        return AppRoutes.auth;
      }
      final session = auth.session;
      if (loc == AppRoutes.marketOps &&
          session != null &&
          !session.isMarketModerator) {
        return AppRoutes.marketMyAds;
      }
      if (loc == AppRoutes.adminStaff &&
          session != null &&
          !session.isPlatformAdmin) {
        return AppRoutes.home;
      }
      if (loc == AppRoutes.foodOps &&
          session != null &&
          !session.isFoodOps) {
        return AppRoutes.food;
      }
      if (loc == AppRoutes.foodMerchantConsole &&
          session != null &&
          !session.isFoodMerchant &&
          !session.isFoodOps) {
        return AppRoutes.food;
      }
      if (loc == AppRoutes.foodRider &&
          session != null &&
          !session.isFoodRider) {
        return AppRoutes.food;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const PhoneScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminStaff,
        builder: (context, state) => const AdminStaffScreen(),
      ),
      GoRoute(
        path: AppRoutes.ride,
        builder: (context, state) => const RideScreen(),
        routes: [
          GoRoute(
            path: 'driver',
            builder: (context, state) => const RideDriverScreen(),
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const RideHistoryScreen(),
          ),
          GoRoute(
            path: 'request',
            builder: (context, state) => const RideScreen(),
          ),
          GoRoute(
            path: 'trips/:id',
            builder: (context, state) => RideTripScreen(
              tripId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.market,
        builder: (context, state) => const MarketScreen(),
        routes: [
          GoRoute(
            path: 'sell',
            builder: (context, state) => MarketSellScreen(
              editAdId: state.uri.queryParameters['edit'],
            ),
          ),
          GoRoute(
            path: 'my-ads',
            builder: (context, state) => const MarketMyAdsScreen(),
          ),
          GoRoute(
            path: 'ops',
            builder: (context, state) => const MarketOpsScreen(),
          ),
          GoRoute(
            path: 'favorites',
            builder: (context, state) => const MarketFavoritesScreen(),
          ),
          GoRoute(
            path: 'messages',
            builder: (context, state) => const MarketMessagesScreen(),
            routes: [
              GoRoute(
                path: ':threadId',
                builder: (context, state) => MarketChatScreen(
                  threadId: state.pathParameters['threadId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'c/:categoryId',
            builder: (context, state) => MarketCategoryScreen(
              categoryId: state.pathParameters['categoryId']!,
            ),
          ),
          GoRoute(
            path: 'ads/:adId',
            builder: (context, state) => MarketAdDetailScreen(
              adId: state.pathParameters['adId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.food,
        builder: (context, state) => const FoodScreen(),
        routes: [
          GoRoute(
            path: 'merchant/:id',
            builder: (context, state) => FoodMerchantScreen(
              merchantId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'cart',
            builder: (context, state) => const FoodCartScreen(),
          ),
          GoRoute(
            path: 'checkout',
            builder: (context, state) => const FoodCheckoutScreen(),
          ),
          GoRoute(
            path: 'console',
            builder: (context, state) => const FoodMerchantConsoleScreen(),
          ),
          GoRoute(
            path: 'rider',
            builder: (context, state) => const FoodRiderScreen(),
          ),
          GoRoute(
            path: 'ops',
            builder: (context, state) => const FoodOpsScreen(),
          ),
          GoRoute(
            path: 'orders',
            builder: (context, state) => const FoodOrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => FoodOrderDetailScreen(
                  orderId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.games,
        builder: (context, state) => const GamesHubScreen(),
        routes: [
          GoRoute(
            path: 'brick-breaker',
            builder: (context, state) => const BrickBreakerScreen(),
          ),
          GoRoute(
            path: 'tetris',
            builder: (context, state) => const TetrisScreen(),
          ),
          GoRoute(
            path: 'candy-crush',
            builder: (context, state) => const CandyCrushScreen(),
          ),
          GoRoute(
            path: 'road-fighter',
            builder: (context, state) => const RoadFighterScreen(),
          ),
        ],
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}
