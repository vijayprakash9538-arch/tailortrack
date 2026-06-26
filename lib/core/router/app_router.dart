import 'package:go_router/go_router.dart';

import '../../common/widgets/app_shell.dart';
import '../../features/customers/presentation/customer_edit_screen.dart';
import '../../features/customers/presentation/customer_profile_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/orders/presentation/new_order_screen.dart';
import '../../features/orders/presentation/order_details_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/splash/splash_screen.dart';

/// Tab order must match [AppShell]'s BottomNavigationBarItems.
const _tabPaths = ['/home', '/orders', '/customers', '/insights'];

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
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
