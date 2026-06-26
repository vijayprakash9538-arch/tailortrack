import '../../customers/domain/measurement.dart';
import 'order_enums.dart';

/// A single tailoring order. `balance` is always derived
/// (totalAmount - advance) and never stored independently, so it can never
/// drift out of sync — see [Order.balance].
class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String phone;
  final String dressType;
  final DateTime deliveryDate;
  final DeliveryTime expectedDeliveryTime;
  final double totalAmount;
  final double advance;
  final OrderStatus status;
  final Measurement? measurement;
  final String? notes;
  final String? photoPath;
  final String? voicePath;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.dressType,
    required this.deliveryDate,
    required this.expectedDeliveryTime,
    required this.totalAmount,
    required this.advance,
    required this.status,
    required this.createdAt,
    this.measurement,
    this.notes,
    this.photoPath,
    this.voicePath,
  });

  double get balance => totalAmount - advance;

  /// An order is overdue when it hasn't been delivered and the delivery
  /// date has already passed — computed live rather than stored, so it
  /// never goes stale.
  bool get isOverdue =>
      status != OrderStatus.delivered &&
      deliveryDate.isBefore(DateTime.now().subtract(const Duration(days: 1)).copyWith(
            hour: 23,
            minute: 59,
          ));

  OrderStatus get effectiveStatus => isOverdue ? OrderStatus.overdue : status;

  Order copyWith({
    String? customerName,
    String? phone,
    String? dressType,
    DateTime? deliveryDate,
    DeliveryTime? expectedDeliveryTime,
    double? totalAmount,
    double? advance,
    OrderStatus? status,
    Measurement? measurement,
    String? notes,
    String? photoPath,
    String? voicePath,
    DateTime? createdAt,
  }) {
    return Order(
      id: id,
      customerId: customerId,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      dressType: dressType ?? this.dressType,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      expectedDeliveryTime: expectedDeliveryTime ?? this.expectedDeliveryTime,
      totalAmount: totalAmount ?? this.totalAmount,
      advance: advance ?? this.advance,
      status: status ?? this.status,
      measurement: measurement ?? this.measurement,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      voicePath: voicePath ?? this.voicePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension _DateTimeCopyWith on DateTime {
  DateTime copyWith({int? hour, int? minute}) {
    return DateTime(year, month, day, hour ?? this.hour, minute ?? this.minute);
  }
}

extension OrderSerialization on Order {
  /// Maps to the `tt_orders` row shape (also used for the local offline cache).
  Map<String, dynamic> toDbMap(String shopId) {
    final d = deliveryDate;
    return {
      'id': id,
      'shop_id': shopId,
      'customer_id': customerId,
      'customer_name': customerName,
      'phone': phone,
      'dress_type': dressType,
      'delivery_date': '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      'expected_delivery_time': expectedDeliveryTime.name,
      'total_amount': totalAmount,
      'advance': advance,
      'status': status.name,
      'measurement_notes': measurement?.notes,
      'notes': notes,
      'photo_path': photoPath,
      'voice_path': voicePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static Order fromDbMap(Map<String, dynamic> m) {
    final mn = m['measurement_notes'] as String?;
    return Order(
      id: m['id'] as String,
      customerId: (m['customer_id'] as String?) ?? '',
      customerName: (m['customer_name'] as String?) ?? '',
      phone: (m['phone'] as String?) ?? '',
      dressType: (m['dress_type'] as String?) ?? '',
      deliveryDate: DateTime.parse(m['delivery_date'] as String),
      expectedDeliveryTime: deliveryTimeFromName(m['expected_delivery_time'] as String?),
      totalAmount: (m['total_amount'] as num?)?.toDouble() ?? 0,
      advance: (m['advance'] as num?)?.toDouble() ?? 0,
      status: orderStatusFromName(m['status'] as String?),
      measurement: (mn == null || mn.isEmpty) ? null : Measurement(notes: mn),
      notes: m['notes'] as String?,
      photoPath: m['photo_path'] as String?,
      voicePath: m['voice_path'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}
