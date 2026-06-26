import 'package:supabase_flutter/supabase_flutter.dart';

import 'offline_store.dart';

/// Pushes a single row upsert to Supabase, queuing it in the outbox if the
/// network is unavailable so it syncs later.
Future<void> upsertOrQueue(SupabaseClient client, String table, String entity, Map<String, dynamic> row) async {
  try {
    await client.from(table).upsert(row);
  } catch (_) {
    await OfflineStore.cached.enqueue(OutboxOp(entity: entity, op: 'upsert', data: row));
  }
}

/// Deletes a row by id, queuing the delete if offline.
Future<void> deleteOrQueue(SupabaseClient client, String table, String entity, String id) async {
  try {
    await client.from(table).delete().eq('id', id);
  } catch (_) {
    await OfflineStore.cached.enqueue(OutboxOp(entity: entity, op: 'delete', data: {'id': id}));
  }
}

/// Replays queued writes in order; keeps any that still fail. Call on app
/// start (per shop) and whenever connectivity returns.
Future<void> flushOutbox(SupabaseClient client) async {
  final store = OfflineStore.cached;
  final ops = store.readOutbox();
  if (ops.isEmpty) return;
  final remaining = <OutboxOp>[];
  for (final op in ops) {
    final table = op.entity == 'order' ? 'tt_orders' : 'tt_customers';
    try {
      if (op.op == 'delete') {
        await client.from(table).delete().eq('id', op.data['id'] as String);
      } else {
        await client.from(table).upsert(op.data);
      }
    } catch (_) {
      remaining.add(op); // still offline / failing — retry next time
    }
  }
  await store.replaceOutbox(remaining);
}
