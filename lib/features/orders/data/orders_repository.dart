import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/offline/offline_store.dart';
import '../../../core/offline/sync.dart';
import '../../../core/storage/media_service.dart';
import '../../authentication/data/auth_controller.dart';
import '../../authentication/data/shop_providers.dart';
import '../domain/order.dart';
import '../domain/order_enums.dart';

/// Supabase-backed store of the shop's orders. Public API (addOrder,
/// updateOrder, updateStatus, delete…) is unchanged from the old in-memory
/// version, so every screen and derived provider keeps working as-is — it
/// just reads/writes Supabase now, with an offline cache + realtime sync.
class OrdersNotifier extends StateNotifier<List<Order>> {
  final SupabaseClient client;
  final MediaService media;
  final String? shopId;
  RealtimeChannel? _channel;

  OrdersNotifier({required this.client, required this.media, required this.shopId}) : super(const []) {
    if (shopId != null) _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1) instant paint from the local cache
    final cached = OfflineStore.cached.readCache('order', shopId!);
    if (cached.isNotEmpty) {
      state = cached.map(OrderSerialization.fromDbMap).toList()..sort(_byCreatedDesc);
    }
    // 2) push anything queued while offline, then 3) fetch fresh, 4) subscribe
    await flushOutbox(client);
    await _refetch();
    _subscribe();
  }

  int _byCreatedDesc(Order a, Order b) => b.createdAt.compareTo(a.createdAt);

  Future<void> _refetch() async {
    try {
      final rows = await client.from('tt_orders').select().eq('shop_id', shopId!);
      final orders = (rows as List).map((e) => OrderSerialization.fromDbMap(Map<String, dynamic>.from(e as Map))).toList()
        ..sort(_byCreatedDesc);
      state = orders;
      await OfflineStore.cached.writeCache('order', shopId!, orders.map((o) => o.toDbMap(shopId!)).toList());
    } catch (_) {
      // Offline — keep whatever the cache gave us.
    }
  }

  void _subscribe() {
    _channel = client
        .channel('tt_orders_$shopId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tt_orders',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'shop_id', value: shopId!),
          callback: (_) => _refetch(),
        )
        .subscribe();
  }

  Future<void> _persist(Order order) async {
    var o = order;
    try {
      final photo = await media.ensurePhotoUploaded(o.photoPath, shopId!);
      final voice = await media.ensureVoiceUploaded(o.voicePath, shopId!);
      o = o.copyWith(photoPath: photo, voicePath: voice);
      // reflect uploaded paths in state/cache
      state = [for (final x in state) if (x.id == o.id) o else x];
    } catch (_) {
      // media upload failed (offline) — keep local paths, still queue the row
    }
    await _cache();
    await upsertOrQueue(client, 'tt_orders', 'order', o.toDbMap(shopId!));
  }

  Future<void> _cache() => OfflineStore.cached.writeCache('order', shopId!, state.map((o) => o.toDbMap(shopId!)).toList());

  void addOrder(Order order) {
    state = [order, ...state];
    _persist(order);
  }

  void updateOrder(Order order) {
    state = [for (final o in state) if (o.id == order.id) order else o];
    _persist(order);
  }

  void updateStatus(String orderId, OrderStatus status) {
    Order? changed;
    state = [
      for (final o in state)
        if (o.id == orderId) (changed = o.copyWith(status: status)) else o,
    ];
    final c = changed;
    if (c != null) _persist(c);
  }

  void deleteOrder(String orderId) {
    state = state.where((o) => o.id != orderId).toList();
    _cache();
    deleteOrQueue(client, 'tt_orders', 'order', orderId);
  }

  void deleteOrdersForCustomer(String customerId) {
    final removed = state.where((o) => o.customerId == customerId).toList();
    state = state.where((o) => o.customerId != customerId).toList();
    _cache();
    for (final o in removed) {
      deleteOrQueue(client, 'tt_orders', 'order', o.id);
    }
  }

  void disposeChannel() {
    if (_channel != null) client.removeChannel(_channel!);
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final shopId = ref.watch(shopIdProvider);
  final notifier = OrdersNotifier(client: client, media: MediaService(client), shopId: shopId);
  ref.onDispose(notifier.disposeChannel);
  return notifier;
});

// ---- Derived providers (unchanged API used across the app) ----

final todaysOrdersProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(ordersProvider);
  final now = DateTime.now();
  return orders.where((o) {
    final d = o.deliveryDate;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }).toList();
});

final readyOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(ordersProvider).where((o) => o.effectiveStatus == OrderStatus.ready).toList();
});

final pendingOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(ordersProvider).where((o) => o.status != OrderStatus.delivered).toList();
});

final pendingPaymentsTotalProvider = Provider<double>((ref) {
  return ref.watch(ordersProvider).fold(0.0, (sum, o) => sum + o.balance);
});

final recentOrdersProvider = Provider<List<Order>>((ref) {
  final orders = List.of(ref.watch(ordersProvider));
  orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return orders;
});
