import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/order.dart';
import '../domain/order_enums.dart';
import 'mock_data.dart';

/// Holds all orders in memory. Swap the body of these methods for Firestore
/// calls when the backend is wired up — the provider surface (the
/// `StateNotifier` API below) is designed to stay the same either way.
class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super(List.of(mockOrders));

  void addOrder(Order order) => state = [order, ...state];

  void updateOrder(Order order) {
    state = [for (final o in state) if (o.id == order.id) order else o];
  }

  void updateStatus(String orderId, OrderStatus status) {
    state = [
      for (final o in state) if (o.id == orderId) o.copyWith(status: status) else o,
    ];
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>((ref) {
  return OrdersNotifier();
});

/// Orders due today, used by Home ("Today's Orders") and Insights
/// ("Today's Delivery Schedule").
final todaysOrdersProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(ordersProvider);
  final now = DateTime.now();
  return orders.where((o) {
    final d = o.deliveryDate;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }).toList();
});

final readyOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(ordersProvider).where((o) => o.effectiveStatus == OrderStatus.ready).toList();
});

final pendingOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(ordersProvider).where((o) => o.status != OrderStatus.delivered).toList();
});

final pendingPaymentsTotalProvider = Provider<double>((ref) {
  return ref.watch(ordersProvider).fold(0.0, (sum, o) => sum + o.balance);
});

/// Sorted newest-first for the Home "Recent Orders" list.
final recentOrdersProvider = Provider<List<Order>>((ref) {
  final orders = List.of(ref.watch(ordersProvider));
  orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return orders;
});
