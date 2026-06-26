import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/data/mock_data.dart';
import '../../orders/data/orders_repository.dart';
import '../domain/customer.dart';
import '../domain/measurement.dart';

class CustomersNotifier extends StateNotifier<List<Customer>> {
  CustomersNotifier() : super(List.of(mockCustomers));

  Customer addOrFind({required String name, required String phone}) {
    final existing = state.where((c) => c.phone == phone).toList();
    if (existing.isNotEmpty) return existing.first;
    final customer = Customer(id: 'c${DateTime.now().microsecondsSinceEpoch}', name: name, phone: phone);
    state = [...state, customer];
    return customer;
  }

  void updateLastMeasurement(String customerId, Measurement measurement) {
    state = [
      for (final c in state)
        if (c.id == customerId) c.copyWith(lastMeasurement: measurement) else c,
    ];
  }

  void updateCustomer(Customer customer) {
    state = [for (final c in state) if (c.id == customer.id) customer else c];
  }
}

final customersProvider = StateNotifierProvider<CustomersNotifier, List<Customer>>((ref) {
  return CustomersNotifier();
});

/// Derived, always-fresh stats per customer — orders are the single source
/// of truth, so totals/pending-balance can never drift out of sync.
class CustomerStats {
  final int totalOrders;
  final double totalSpent;
  final double pendingBalance;

  const CustomerStats({required this.totalOrders, required this.totalSpent, required this.pendingBalance});
}

final customerStatsProvider = Provider.family<CustomerStats, String>((ref, customerId) {
  final orders = ref.watch(ordersProvider).where((o) => o.customerId == customerId);
  final totalOrders = orders.length;
  final totalSpent = orders.fold(0.0, (sum, o) => sum + o.totalAmount);
  final pendingBalance = orders.fold(0.0, (sum, o) => sum + o.balance);
  return CustomerStats(totalOrders: totalOrders, totalSpent: totalSpent, pendingBalance: pendingBalance);
});

/// Customers ranked by order count, then total spend — feeds Insights
/// "Top Customers".
final topCustomersProvider = Provider<List<Customer>>((ref) {
  final customers = List.of(ref.watch(customersProvider));
  customers.sort((a, b) {
    final statsA = ref.watch(customerStatsProvider(a.id));
    final statsB = ref.watch(customerStatsProvider(b.id));
    final byOrders = statsB.totalOrders.compareTo(statsA.totalOrders);
    if (byOrders != 0) return byOrders;
    return statsB.totalSpent.compareTo(statsA.totalSpent);
  });
  return customers;
});
