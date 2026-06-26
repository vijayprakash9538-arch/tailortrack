import '../../customers/domain/customer.dart';
import '../../customers/domain/measurement.dart';
import '../domain/order.dart';
import '../domain/order_enums.dart';

/// Seed data shown on first launch so every screen has something realistic
/// to render before real orders are created. Spans several months so the
/// Insights "Monthly Collected" trend has real data to chart.
DateTime _delivery(int daysFromToday) => DateTime.now().add(Duration(days: daysFromToday));
DateTime _placed(int monthsAgo, int day) {
  final now = DateTime.now();
  return DateTime(now.year, now.month - monthsAgo, day);
}

final List<Customer> mockCustomers = [
  const Customer(
    id: 'c1',
    name: 'Priya',
    phone: '98765 43210',
    lastMeasurement: Measurement(
      notes: 'Chest 34, Waist 28, Shoulder 14, Sleeve 9, Length 14, Neck 7\n'
          'Pant: Waist 30, Hip 38, Length 38, Thigh 22\n'
          'Boat neck, back open with dori',
    ),
  ),
  const Customer(id: 'c2', name: 'Kavya', phone: '91234 56789'),
  const Customer(id: 'c3', name: 'Swathi', phone: '99887 66554'),
  const Customer(id: 'c4', name: 'Anjali', phone: '87965 43211'),
  const Customer(id: 'c5', name: 'Radhika', phone: '81234 56789'),
  // Duplicate display name "Priya" with a different phone — they are distinct
  // customers. The repeat-customer flow keys off phone, not name, so this
  // verifies name collisions don't merge records.
  const Customer(
    id: 'c6',
    name: 'Priya',
    phone: '90000 11111',
    lastMeasurement: Measurement(notes: 'Chest 36, Waist 30, Shoulder 15, Sleeve 10, Length 15, Neck 7'),
  ),
  const Customer(id: 'c7', name: 'Meena', phone: '93333 22221'),
  const Customer(id: 'c8', name: 'Lakshmi', phone: '94444 55556'),
];

final List<Order> mockOrders = [
  // ---- Current month / this week ----
  Order(
    id: 'o1', customerId: 'c1', customerName: 'Priya', phone: '98765 43210',
    dressType: 'Blouse', deliveryDate: _delivery(0), expectedDeliveryTime: DeliveryTime.morning,
    totalAmount: 850, advance: 200, status: OrderStatus.stitching, createdAt: _placed(0, 5),
    measurement: mockCustomers[0].lastMeasurement,
  ),
  Order(
    id: 'o2', customerId: 'c2', customerName: 'Kavya', phone: '91234 56789',
    dressType: 'Chudidar', deliveryDate: _delivery(-1), expectedDeliveryTime: DeliveryTime.afternoon,
    totalAmount: 650, advance: 300, status: OrderStatus.ready, createdAt: _placed(0, 3),
  ),
  Order(
    id: 'o3', customerId: 'c4', customerName: 'Anjali', phone: '87965 43211',
    dressType: 'Lehenga', deliveryDate: _delivery(-3), expectedDeliveryTime: DeliveryTime.evening,
    totalAmount: 2100, advance: 1000, status: OrderStatus.pending, createdAt: _placed(0, 1),
  ),
  Order(
    id: 'o5', customerId: 'c5', customerName: 'Radhika', phone: '81234 56789',
    dressType: 'Gown', deliveryDate: _delivery(0), expectedDeliveryTime: DeliveryTime.afternoon,
    totalAmount: 1800, advance: 600, status: OrderStatus.pending, createdAt: _placed(0, 6),
  ),
  Order(
    id: 'o6', customerId: 'c2', customerName: 'Kavya', phone: '91234 56789',
    dressType: 'Blouse', deliveryDate: _delivery(2), expectedDeliveryTime: DeliveryTime.evening,
    totalAmount: 700, advance: 300, status: OrderStatus.stitching, createdAt: _placed(0, 7),
  ),
  Order(
    id: 'o9', customerId: 'c6', customerName: 'Priya', phone: '90000 11111',
    dressType: 'Kurti', deliveryDate: _delivery(4), expectedDeliveryTime: DeliveryTime.morning,
    totalAmount: 900, advance: 0, status: OrderStatus.pending, createdAt: _placed(0, 8),
    measurement: mockCustomers[5].lastMeasurement,
  ),
  // ---- Current month, delivered & fully paid ----
  Order(
    id: 'o4', customerId: 'c3', customerName: 'Swathi', phone: '99887 66554',
    dressType: 'Saree Fall', deliveryDate: _delivery(-4), expectedDeliveryTime: DeliveryTime.morning,
    totalAmount: 250, advance: 250, status: OrderStatus.delivered, createdAt: _placed(0, 2),
  ),
  // ---- Last month ----
  Order(
    id: 'o7', customerId: 'c7', customerName: 'Meena', phone: '93333 22221',
    dressType: 'Chudidar', deliveryDate: _placed(1, 20), expectedDeliveryTime: DeliveryTime.afternoon,
    totalAmount: 800, advance: 800, status: OrderStatus.delivered, createdAt: _placed(1, 12),
  ),
  Order(
    id: 'o8', customerId: 'c8', customerName: 'Lakshmi', phone: '94444 55556',
    dressType: 'Lehenga', deliveryDate: _placed(1, 25), expectedDeliveryTime: DeliveryTime.evening,
    totalAmount: 2500, advance: 1500, status: OrderStatus.delivered, createdAt: _placed(1, 10),
  ),
  // ---- Two & three months ago ----
  Order(
    id: 'o10', customerId: 'c1', customerName: 'Priya', phone: '98765 43210',
    dressType: 'Blouse', deliveryDate: _placed(2, 18), expectedDeliveryTime: DeliveryTime.morning,
    totalAmount: 600, advance: 600, status: OrderStatus.delivered, createdAt: _placed(2, 9),
  ),
  Order(
    id: 'o11', customerId: 'c4', customerName: 'Anjali', phone: '87965 43211',
    dressType: 'Alteration', deliveryDate: _placed(3, 15), expectedDeliveryTime: DeliveryTime.afternoon,
    totalAmount: 300, advance: 300, status: OrderStatus.delivered, createdAt: _placed(3, 8),
  ),
];
