import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/widgets/app_shell.dart';
import '../../features/authentication/presentation/forgot_password_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/reset_password_screen.dart';
import '../../features/authentication/presentation/signup_screen.dart';
import '../../features/customers/presentation/customer_edit_screen.dart';
import '../../features/customers/presentation/customer_profile_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/orders/presentation/new_order_screen.dart';
import '../../features/orders/presentation/order_details_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/splash_screen.dart';

/// Tab order must match [AppShell]'s BottomNavigationBarItems.
const _tabPaths = ['/home', '/orders', '/customers', '/insights'];

const _authPaths = ['/login', '/signup', '/forgot-password'];

/// Rebuilds the router's redirect whenever auth state changes, and remembers
/// whether we're in a password-recovery flow.
class _AuthRefresh extends ChangeNotifier {
  AuthChangeEvent? lastEvent;
  late final StreamSubscription<AuthState> _sub;

  _AuthRefresh() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      lastEvent = state.event;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authRefresh = _AuthRefresh();

final appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: _authRefresh,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final loggedIn = session != null;
    final path = state.uri.path;

    // Arriving from a password-reset email → force the reset screen.
    if (_authRefresh.lastEvent == AuthChangeEvent.passwordRecovery && path != '/reset-password') {
      return '/reset-password';
    }

    // Let the splash animation play; it routes onward itself.
    if (path == '/splash') return null;

    final onAuthScreen = _authPaths.contains(path) || path == '/reset-password';

    if (!loggedIn) return onAuthScreen ? null : '/login';
    // Logged in but sitting on an auth screen → go home.
    if (loggedIn && _authPaths.contains(path)) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
    GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordScreen()),
    GoRoute(
      path: '/new-order',
      builder: (context, state) => NewOrderScreen(repeatCustomerId: state.extra as String?),
    ),
    GoRoute(
      path: '/edit-order/:id',
      builder: (context, state) => NewOrderScreen(editOrderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/order/:id',
      builder: (context, state) => OrderDetailsScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/edit-customer/:id',
      builder: (context, state) => CustomerEditScreen(customerId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/customer/:id',
      builder: (context, state) => CustomerProfileScreen(customerId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ShellRoute(
      builder: (context, state, child) {
        final index = _tabPaths.indexWhere((p) => state.uri.path.startsWith(p));
        return AppShell(
          currentIndex: index < 0 ? 0 : index,
          onTap: (i) => context.go(_tabPaths[i]),
          child: child,
        );
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
        GoRoute(path: '/customers', builder: (context, state) => const CustomersScreen()),
        GoRoute(path: '/insights', builder: (context, state) => const InsightsScreen()),
      ],
    ),
  ],
);
