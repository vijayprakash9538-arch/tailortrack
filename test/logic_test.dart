import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tailor_track/features/customers/data/customers_repository.dart';
import 'package:tailor_track/features/insights/presentation/insights_providers.dart';
import 'package:tailor_track/features/orders/data/orders_repository.dart';
import 'package:tailor_track/features/orders/domain/order.dart';
import 'package:tailor_track/features/orders/domain/order_enums.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('Order balance', () {
    test('balance = total - advance', () {
      final o = Order(
        id: 'x', customerId: 'c', customerName: 'A', phone: '1',
        dressType: 'Blouse', deliveryDate: DateTime.now(), expectedDeliveryTime: DeliveryTime.morning,
        totalAmount: 1000, advance: 400, status: OrderStatus.pending, createdAt: DateTime.now(),
      );
      expect(o.balance, 600);
    });

    test('fully settling sets balance to zero', () {
      final o = Order(
        id: 'x', customerId: 'c', customerName: 'A', phone: '1',
        dressType: 'Blouse', deliveryDate: DateTime.now(), expectedDeliveryTime: DeliveryTime.morning,
        totalAmount: 1000, advance: 400, status: OrderStatus.pending, createdAt: DateTime.now(),
      );
      expect(o.copyWith(advance: o.totalAmount).balance, 0);
    });
  });

  group('Order status workflow', () {
    test('next advances through the workflow then stops', () {
      expect(OrderStatus.pending.next, OrderStatus.stitching);
      expect(OrderStatus.stitching.next, OrderStatus.ready);
      expect(OrderStatus.ready.next, OrderStatus.delivered);
      expect(OrderStatus.delivered.next, isNull);
    });
  });

  group('Customer dedup (addOrFind)', () {
    test('same phone returns the existing customer', () {
      final c = _container();
      final notifier = c.read(customersProvider.notifier);
      final before = c.read(customersProvider).length;
      final found = notifier.addOrFind(name: 'Whoever', phone: '98765 43210');
      expect(found.id, 'c1');
      expect(c.read(customersProvider).length, before, reason: 'no new customer created');
    });

    test('same name but new phone creates a distinct customer', () {
      final c = _container();
      final notifier = c.read(customersProvider.notifier);
      final before = c.read(customersProvider).length;
      final created = notifier.addOrFind(name: 'Priya', phone: '70000 00000');
      expect(created.id, isNot('c1'));
      expect(c.read(customersProvider).length, before + 1);
    });

    test('duplicate display names remain separate records', () {
      final c = _container();
      final priyas = c.read(customersProvider).where((x) => x.name == 'Priya').toList();
      expect(priyas.length, greaterThanOrEqualTo(2));
      expect(priyas.map((e) => e.phone).toSet().length, priyas.length, reason: 'distinct phones');
    });
  });

  group('Customer stats', () {
    test('aggregate totals are derived from that customer\'s orders', () {
      final c = _container();
      final stats = c.read(customerStatsProvider('c1'));
      // c1 (Priya, 98765 43210) has o1 (850/adv200) and o10 (600/adv600).
      expect(stats.totalOrders, 2);
      expect(stats.totalSpent, 1450);
      expect(stats.pendingBalance, 650);
    });
  });

  group('Business health accounting', () {
    test('collected + pending always reconciles to order value', () {
      final c = _container();
      final h = c.read(businessHealthProvider);
      expect(h.collected + h.pending, h.orderValue);
    });

    test('pending collection equals sum of all balances (all-time)', () {
      final c = _container();
      // Business Health defaults to the current month — switch to All Time
      // to compare against every order's balance.
      c.read(insightsMonthProvider.notifier).state = null;
      final h = c.read(businessHealthProvider);
      final expected = c.read(ordersProvider).fold<double>(0, (s, o) => s + o.balance);
      expect(h.pending, expected);
    });
  });

  group('Insights month filter', () {
    test('filtering to the current month narrows the order set', () {
      final c = _container();
      final all = c.read(ordersProvider).length;
      final now = DateTime.now();
      c.read(insightsMonthProvider.notifier).state = DateTime(now.year, now.month, 1);
      final filtered = c.read(monthFilteredOrdersProvider);
      expect(filtered.length, lessThan(all));
      expect(filtered.every((o) => o.createdAt.month == now.month && o.createdAt.year == now.year), isTrue);
    });

    test('All Time (null) includes every order', () {
      final c = _container();
      c.read(insightsMonthProvider.notifier).state = null;
      expect(c.read(monthFilteredOrdersProvider).length, c.read(ordersProvider).length);
    });
  });

  group('Top customers ranking', () {
    test('sorted by order count then spend, highest first', () {
      final c = _container();
      final top = c.read(topCustomersProvider);
      for (var i = 0; i < top.length - 1; i++) {
        final a = c.read(customerStatsProvider(top[i].id));
        final b = c.read(customerStatsProvider(top[i + 1].id));
        final ok = a.totalOrders > b.totalOrders ||
            (a.totalOrders == b.totalOrders && a.totalSpent >= b.totalSpent);
        expect(ok, isTrue, reason: 'rank ${top[i].name} should outrank ${top[i + 1].name}');
      }
    });
  });

  group('Today schedule grouping', () {
    test('counts only today\'s orders by delivery time', () {
      final c = _container();
      final sched = c.read(deliveryScheduleProvider);
      final todays = c.read(todaysOrdersProvider).length;
      expect(sched.morning + sched.afternoon + sched.evening, todays);
    });
  });
}
