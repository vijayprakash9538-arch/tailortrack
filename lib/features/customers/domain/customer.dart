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

  /// Maps to the `tt_customers` row shape (also used for the offline cache).
  Map<String, dynamic> toDbMap(String shopId) => {
        'id': id,
        'shop_id': shopId,
        'name': name,
        'phone': phone,
        'measurement_notes': lastMeasurement?.notes,
      };

  static Customer fromDbMap(Map<String, dynamic> m) {
    final mn = m['measurement_notes'] as String?;
    return Customer(
      id: m['id'] as String,
      name: (m['name'] as String?) ?? '',
      phone: (m['phone'] as String?) ?? '',
      lastMeasurement: (mn == null || mn.isEmpty) ? null : Measurement(notes: mn),
    );
  }
}
