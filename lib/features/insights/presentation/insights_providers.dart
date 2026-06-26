import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order.dart';

/// Selected month for the earnings summary. `null` = All Time. When set, it's
/// the first day of the chosen month and filters by each order's placed date
/// ([Order.createdAt]). Defaults to the **current month** so Business Health
/// opens on this month's earnings.
final insightsMonthProvider = StateProvider<DateTime?>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

bool _inMonth(DateTime date, DateTime? month) {
  if (month == null) return true;
  return date.year == month.year && date.month == month.month;
}

/// Orders placed within the selected month (or all orders for All Time).
final monthFilteredOrdersProvider = Provider<List<Order>>((ref) {
  final month = ref.watch(insightsMonthProvider);
  return ref.watch(ordersProvider).where((o) => _inMonth(o.createdAt, month)).toList();
});

/// The list of months offered in the filter dropdown: All Time + the last 6
/// months (newest first).
final availableMonthsProvider = Provider<List<DateTime?>>((ref) {
  final now = DateTime.now();
  return <DateTime?>[
    null,
    for (var i = 0; i < 6; i++) DateTime(now.year, now.month - i, 1),
  ];
});

/// Accounting note — these are kept deliberately distinct so the numbers
/// reconcile:
///   collected + pending == orderValue, always.
/// - [orderValue]  = sum of every order's total (business booked)
/// - [collected]   = sum of advances actually received (income in hand);
///                   settling an order at delivery sets advance = total, so
///                   a fully-paid order's full amount counts here
/// - [pending]     = sum of outstanding balances still to collect
class BusinessHealth {
  final int totalOrders;
  final double orderValue;
  final double collected;
  final double pending;

  const BusinessHealth({
    required this.totalOrders,
    required this.orderValue,
    required this.collected,
    required this.pending,
  });
}

final businessHealthProvider = Provider<BusinessHealth>((ref) {
  final orders = ref.watch(monthFilteredOrdersProvider);
  return BusinessHealth(
    totalOrders: orders.length,
    orderValue: orders.fold(0.0, (s, o) => s + o.totalAmount),
    collected: orders.fold(0.0, (s, o) => s + o.advance),
    pending: orders.fold(0.0, (s, o) => s + o.balance),
  );
});

class MonthlyEarning {
  final String label; // e.g. "Jun"
  final double collected;
  const MonthlyEarning(this.label, this.collected);
}

/// Real collected-income per month for the last 6 months (always all data,
/// independent of the filter, since it's a trend). Each month sums the
/// advances received on orders placed that month.
final monthlyTrendProvider = Provider<List<MonthlyEarning>>((ref) {
  final orders = ref.watch(ordersProvider);
  final now = DateTime.now();
  final result = <MonthlyEarning>[];
  for (var i = 5; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i, 1);
    final collected = orders
        .where((o) => o.createdAt.year == m.year && o.createdAt.month == m.month)
        .fold(0.0, (s, o) => s + o.advance);
    result.add(MonthlyEarning(DateFormat('MMM').format(m), collected));
  }
  return result;
});

class DressTypeShare {
  final String dressType;
  final int count;
  const DressTypeShare(this.dressType, this.count);
}

/// Donut breakdown — counts orders per dress type within the selected month.
final dressTypeAnalyticsProvider = Provider<List<DressTypeShare>>((ref) {
  final orders = ref.watch(monthFilteredOrdersProvider);
  final counts = <String, int>{};
  for (final o in orders) {
    counts[o.dressType] = (counts[o.dressType] ?? 0) + 1;
  }
  final entries = counts.entries.map((e) => DressTypeShare(e.key, e.value)).toList();
  entries.sort((a, b) => b.count.compareTo(a.count));
  return entries;
});

class DeliverySchedule {
  final int morning;
  final int afternoon;
  final int evening;
  const DeliverySchedule({required this.morning, required this.afternoon, required this.evening});
}

/// Groups today's orders by delivery time — always current, not affected by
/// the month filter.
final deliveryScheduleProvider = Provider<DeliverySchedule>((ref) {
  final todays = ref.watch(todaysOrdersProvider);
  return DeliverySchedule(
    morning: todays.where((o) => o.expectedDeliveryTime.name == 'morning').length,
    afternoon: todays.where((o) => o.expectedDeliveryTime.name == 'afternoon').length,
    evening: todays.where((o) => o.expectedDeliveryTime.name == 'evening').length,
  );
});
