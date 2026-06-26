import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/order_enums.dart';

/// The list of dress types offered in the New Order picker. Seeded from
/// [dressTypeOptions] but extensible at runtime — tailors can add a new type
/// on the fly, and because Insights derives its dress-type analytics from the
/// orders themselves, any new type automatically shows up there too.
class DressTypesNotifier extends StateNotifier<List<String>> {
  DressTypesNotifier() : super(List.of(dressTypeOptions));

  void add(String type) {
    final t = type.trim();
    if (t.isEmpty || state.contains(t)) return;
    state = [...state, t];
  }
}

final dressTypesProvider = StateNotifierProvider<DressTypesNotifier, List<String>>((ref) {
  return DressTypesNotifier();
});
