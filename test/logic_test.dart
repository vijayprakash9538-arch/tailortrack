import 'package:flutter_test/flutter_test.dart';

import 'package:tailor_track/features/customers/domain/customer.dart';
import 'package:tailor_track/features/customers/domain/measurement.dart';
import 'package:tailor_track/features/orders/domain/order.dart';
import 'package:tailor_track/features/orders/domain/order_enums.dart';

Order _order({double total = 1000, double advance = 400, OrderStatus status = OrderStatus.pending}) => Order(
      id: 'id-1',
      customerId: 'cust-1',
      customerName: 'Priya',
      phone: '98765 43210',
      dressType: 'Blouse',
      deliveryDate: DateTime(2026, 6, 28),
      expectedDeliveryTime: DeliveryTime.morning,
      totalAmount: total,
      advance: advance,
      status: status,
      createdAt: DateTime(2026, 6, 20, 10, 30),
      measurement: const Measurement(notes: 'Chest 34, Waist 28'),
      notes: 'Boat neck',
    );

void main() {
  group('Order balance', () {
    test('balance = total - advance', () => expect(_order().balance, 600));
    test('fully settling sets balance to zero', () => expect(_order().copyWith(advance: 1000).balance, 0));
  });

  group('Order status workflow', () {
    test('next advances through the workflow then stops', () {
      expect(OrderStatus.pending.next, OrderStatus.stitching);
      expect(OrderStatus.stitching.next, OrderStatus.ready);
      expect(OrderStatus.ready.next, OrderStatus.delivered);
      expect(OrderStatus.delivered.next, isNull);
    });
    test('parses status/time names safely with a fallback', () {
      expect(orderStatusFromName('ready'), OrderStatus.ready);
      expect(orderStatusFromName('nonsense'), OrderStatus.pending);
      expect(deliveryTimeFromName('evening'), DeliveryTime.evening);
      expect(deliveryTimeFromName(null), DeliveryTime.morning);
    });
  });

  group('Order DB serialization', () {
    test('round-trips through the tt_orders row shape', () {
      final original = _order();
      final row = original.toDbMap('shop-9');
      expect(row['shop_id'], 'shop-9');
      expect(row['delivery_date'], '2026-06-28');
      expect(row['expected_delivery_time'], 'morning');
      expect(row['status'], 'pending');
      expect(row['measurement_notes'], 'Chest 34, Waist 28');

      final back = OrderSerialization.fromDbMap(row);
      expect(back.id, original.id);
      expect(back.totalAmount, original.totalAmount);
      expect(back.balance, original.balance);
      expect(back.deliveryDate, original.deliveryDate);
      expect(back.expectedDeliveryTime, original.expectedDeliveryTime);
      expect(back.measurement?.notes, original.measurement?.notes);
    });
  });

  group('Customer DB serialization', () {
    test('round-trips through the tt_customers row shape', () {
      const c = Customer(id: 'c1', name: 'Kavya', phone: '91234 56789', lastMeasurement: Measurement(notes: 'Waist 30'));
      final row = c.toDbMap('shop-9');
      expect(row['shop_id'], 'shop-9');
      expect(row['measurement_notes'], 'Waist 30');
      final back = Customer.fromDbMap(row);
      expect(back.id, 'c1');
      expect(back.name, 'Kavya');
      expect(back.lastMeasurement?.notes, 'Waist 30');
    });
  });
}
