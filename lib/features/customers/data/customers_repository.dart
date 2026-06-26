import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/offline/offline_store.dart';
import '../../../core/offline/sync.dart';
import '../../authentication/data/auth_controller.dart';
import '../../authentication/data/shop_providers.dart';
import '../../orders/data/orders_repository.dart';
import '../domain/customer.dart';
import '../domain/measurement.dart';

const _uuid = Uuid();

/// Supabase-backed store of the shop's customers. Same public API as before
/// (addOrFind, updateLastMeasurement, updateCustomer, deleteCustomer) so the
/// UI is untouched; data now persists and syncs across devices.
class CustomersNotifier extends StateNotifier<List<Customer>> {
  final SupabaseClient client;
  final String? shopId;
  RealtimeChannel? _channel;

  CustomersNotifier({required this.client, required this.shopId}) : super(const []) {
    if (shopId != null) _bootstrap();
  }

  Future<void> _bootstrap() async {
    final cached = OfflineStore.cached.readCache('customer', shopId!);
    if (cached.isNotEmpty) state = cached.map(Customer.fromDbMap).toList();
    await flushOutbox(client);
    await _refetch();
    _subscribe();
  }

  Future<void> _refetch() async {
    try {
      final rows = await client.from('tt_customers').select().eq('shop_id', shopId!).order('name');
      state = (rows as List).map((e) => Customer.fromDbMap(Map<String, dynamic>.from(e as Map))).toList();
      await OfflineStore.cached.writeCache('customer', shopId!, state.map((c) => c.toDbMap(shopId!)).toList());
    } catch (_) {
      // offline — keep cache
    }
  }

  void _subscribe() {
    _channel = client
        .channel('tt_customers_$shopId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tt_customers',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'shop_id', value: shopId!),
          callback: (_) => _refetch(),
        )
        .subscribe();
  }

  Future<void> _cache() => OfflineStore.cached.writeCache('customer', shopId!, state.map((c) => c.toDbMap(shopId!)).toList());

  /// Returns the existing customer for this phone, or creates one. Stays
  /// synchronous (optimistic) so the New Order flow is instant; the write is
  /// pushed in the background.
  Customer addOrFind({required String name, required String phone}) {
    final existing = state.where((c) => c.phone == phone).toList();
    if (existing.isNotEmpty) return existing.first;
    final customer = Customer(id: _uuid.v4(), name: name, phone: phone);
    state = [...state, customer];
    _cache();
    if (shopId != null) upsertOrQueue(client, 'tt_customers', 'customer', customer.toDbMap(shopId!));
    return customer;
  }

  void updateLastMeasurement(String customerId, Measurement measurement) {
    Customer? changed;
    state = [
      for (final c in state)
        if (c.id == customerId) (changed = c.copyWith(lastMeasurement: measurement)) else c,
    ];
    final c = changed;
    if (c != null && shopId != null) {
      _cache();
      upsertOrQueue(client, 'tt_customers', 'customer', c.toDbMap(shopId!));
    }
  }

  void updateCustomer(Customer customer) {
    state = [for (final c in state) if (c.id == customer.id) customer else c];
    if (shopId != null) {
      _cache();
      upsertOrQueue(client, 'tt_customers', 'customer', customer.toDbMap(shopId!));
    }
  }

  void deleteCustomer(String customerId) {
    state = state.where((c) => c.id != customerId).toList();
    if (shopId != null) {
      _cache();
      deleteOrQueue(client, 'tt_customers', 'customer', customerId);
    }
  }

  void disposeChannel() {
    if (_channel != null) client.removeChannel(_channel!);
  }
}

final customersProvider = StateNotifierProvider<CustomersNotifier, List<Customer>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final shopId = ref.watch(shopIdProvider);
  final notifier = CustomersNotifier(client: client, shopId: shopId);
  ref.onDispose(notifier.disposeChannel);
  return notifier;
});

// ---- Derived providers (unchanged) ----

class CustomerStats {
  final int totalOrders;
  final double totalSpent;
  final double pendingBalance;
  const CustomerStats({required this.totalOrders, required this.totalSpent, required this.pendingBalance});
}

final customerStatsProvider = Provider.family<CustomerStats, String>((ref, customerId) {
  final orders = ref.watch(ordersProvider).where((o) => o.customerId == customerId);
  return CustomerStats(
    totalOrders: orders.length,
    totalSpent: orders.fold(0.0, (sum, o) => sum + o.totalAmount),
    pendingBalance: orders.fold(0.0, (sum, o) => sum + o.balance),
  );
});

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
