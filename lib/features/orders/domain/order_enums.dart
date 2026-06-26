import 'package:flutter/material.dart';

/// Status of a tailoring order, in workflow order.
enum OrderStatus { pending, stitching, ready, delivered, overdue }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.stitching:
        return 'Stitching';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.overdue:
        return 'Overdue';
    }
  }

  /// The progress steps a tailor moves an order through, in order. Overdue
  /// is a derived state (see [Order.effectiveStatus]) and is never set
  /// manually, so it's excluded here.
  static const List<OrderStatus> workflow = [
    OrderStatus.pending,
    OrderStatus.stitching,
    OrderStatus.ready,
    OrderStatus.delivered,
  ];

  /// The next step in the workflow, or null if already delivered. Lets the
  /// Orders screen offer a one-tap "advance progress" action.
  OrderStatus? get next {
    final i = workflow.indexOf(this);
    if (i < 0 || i >= workflow.length - 1) return null;
    return workflow[i + 1];
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_empty_rounded;
      case OrderStatus.stitching:
        return Icons.content_cut_rounded;
      case OrderStatus.ready:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.delivered:
        return Icons.local_shipping_rounded;
      case OrderStatus.overdue:
        return Icons.warning_amber_rounded;
    }
  }
}

OrderStatus orderStatusFromName(String? name) {
  return OrderStatus.values.firstWhere(
    (s) => s.name == name,
    orElse: () => OrderStatus.pending,
  );
}

/// Time-of-day window the customer expects delivery — drives the
/// Insights "Today's Delivery Schedule" grouping.
enum DeliveryTime { morning, afternoon, evening }

DeliveryTime deliveryTimeFromName(String? name) {
  return DeliveryTime.values.firstWhere(
    (t) => t.name == name,
    orElse: () => DeliveryTime.morning,
  );
}

extension DeliveryTimeX on DeliveryTime {
  String get label {
    switch (this) {
      case DeliveryTime.morning:
        return 'Morning';
      case DeliveryTime.afternoon:
        return 'Afternoon';
      case DeliveryTime.evening:
        return 'Evening';
    }
  }
}

/// Dress types offered by the shop. Kept as an open list (not an enum) in
/// [dressTypeOptions] so new types can be added without a code change.
const List<String> dressTypeOptions = [
  'Blouse',
  'Chudidar',
  'Lehenga',
  'Saree Fall',
  'Alteration',
  'Gown',
  'Kurti',
];
