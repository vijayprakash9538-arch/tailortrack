import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/offline_store.dart';
import 'auth_controller.dart';

/// The tailoring shop owned by the signed-in user. Created automatically on
/// signup by the database trigger; every customer/order is scoped to its id.
class Shop {
  final String id;
  final String shopName;
  final String? ownerName;
  final String? email;

  const Shop({required this.id, required this.shopName, this.ownerName, this.email});

  factory Shop.fromMap(Map<String, dynamic> map) => Shop(
        id: map['id'] as String,
        shopName: (map['shop_name'] as String?) ?? 'My Tailoring Shop',
        ownerName: map['owner_name'] as String?,
        email: map['email'] as String?,
      );
}

/// Loads the current user's shop. Re-evaluates whenever auth state changes
/// (login/logout), so data scoping follows the active session.
final currentShopProvider = FutureProvider<Shop?>((ref) async {
  ref.watch(authStateChangesProvider); // re-fetch on sign-in / sign-out
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;

  // The signup trigger creates the row; retry briefly in case we beat it.
  // On success the row is cached so the app can still resolve the shop (and
  // therefore show cached orders/customers) when offline.
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      final rows = await client.from('tt_shops').select().eq('owner_id', user.id).limit(1);
      if (rows.isNotEmpty) {
        await OfflineStore.cached.writeShop(rows.first);
        return Shop.fromMap(rows.first);
      }
    } catch (_) {
      break; // offline — use the cached shop below
    }
    await Future.delayed(const Duration(milliseconds: 400));
  }

  // Offline fallback: last known shop for this same user.
  final cached = OfflineStore.cached.readShop();
  if (cached != null && cached['owner_id'] == user.id) return Shop.fromMap(cached);
  return null;
});

/// Convenience: the current shop id (or null when signed out / not ready).
final shopIdProvider = Provider<String?>((ref) {
  return ref.watch(currentShopProvider).asData?.value?.id;
});
