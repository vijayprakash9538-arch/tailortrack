import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A single queued write that couldn't reach Supabase (offline). Flushed in
/// order when connectivity returns.
class OutboxOp {
  final String entity; // 'order' | 'customer'
  final String op; // 'upsert' | 'delete'
  final Map<String, dynamic> data; // row for upsert, or {'id': ...} for delete

  OutboxOp({required this.entity, required this.op, required this.data});

  Map<String, dynamic> toJson() => {'entity': entity, 'op': op, 'data': data};
  factory OutboxOp.fromJson(Map<String, dynamic> j) =>
      OutboxOp(entity: j['entity'] as String, op: j['op'] as String, data: Map<String, dynamic>.from(j['data'] as Map));
}

/// Local persistence for offline support: a read cache of each shop's
/// customers/orders (so the app opens instantly and works with no network)
/// plus an outbox of pending writes.
class OfflineStore {
  OfflineStore._(this._prefs);
  final SharedPreferences _prefs;

  static OfflineStore? _instance;
  static Future<OfflineStore> instance() async {
    return _instance ??= OfflineStore._(await SharedPreferences.getInstance());
  }

  /// Synchronous accessor — valid only after [instance] has been awaited once
  /// (done in `main` before the app runs).
  static OfflineStore get cached => _instance!;

  // ---- Read cache (per shop) ----
  String _cacheKey(String entity, String shopId) => 'tt_cache_${entity}_$shopId';

  List<Map<String, dynamic>> readCache(String entity, String shopId) {
    final raw = _prefs.getString(_cacheKey(entity, shopId));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> writeCache(String entity, String shopId, List<Map<String, dynamic>> rows) {
    return _prefs.setString(_cacheKey(entity, shopId), jsonEncode(rows));
  }

  // ---- Last known shop (so the app opens offline) ----
  static const _shopKey = 'tt_last_shop';

  Map<String, dynamic>? readShop() {
    final raw = _prefs.getString(_shopKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> writeShop(Map<String, dynamic> shop) => _prefs.setString(_shopKey, jsonEncode(shop));

  // ---- Outbox ----
  static const _outboxKey = 'tt_outbox';

  List<OutboxOp> readOutbox() {
    final raw = _prefs.getString(_outboxKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => OutboxOp.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> _writeOutbox(List<OutboxOp> ops) {
    return _prefs.setString(_outboxKey, jsonEncode(ops.map((e) => e.toJson()).toList()));
  }

  Future<void> enqueue(OutboxOp op) async {
    final ops = readOutbox()..add(op);
    await _writeOutbox(ops);
  }

  Future<void> clearOutbox() => _prefs.remove(_outboxKey);

  Future<void> replaceOutbox(List<OutboxOp> ops) => _writeOutbox(ops);
}
