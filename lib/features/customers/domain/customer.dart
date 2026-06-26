import 'measurement.dart';

/// A shop customer. Aggregated stats (totalOrders, totalSpent,
/// pendingBalance) are derived from their orders, not stored as
/// source-of-truth — see `customerStatsProvider` in the customers feature.
class Customer {
  final String id;
  final String name;
  final String phone;
  final Measurement? lastMeasurement;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.lastMeasurement,
  });

  Customer copyWith({String? name, String? phone, Measurement? lastMeasurement}) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      lastMeasurement: lastMeasurement ?? this.lastMeasurement,
    );
  }
}
