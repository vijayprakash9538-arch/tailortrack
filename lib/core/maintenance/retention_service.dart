import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/authentication/data/auth_controller.dart';
import '../../features/authentication/data/shop_providers.dart';
import '../storage/media_service.dart';

/// Deletes expired order media to keep storage lean, while **never** touching
/// the order/customer records themselves:
///   - photos older than 60 days
///   - voice notes older than 30 days
///
/// Throttled to run at most once per day (tracked in SharedPreferences), so
/// simply opening the app keeps storage tidy without any manual action.
class RetentionService {
  final SupabaseClient client;
  final String shopId;
  RetentionService(this.client, this.shopId);

  static const _lastRunKey = 'tt_retention_last_run';
  static const _photoMaxAgeDays = 60;
  static const _voiceMaxAgeDays = 30;

  Future<void> runIfDue() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastRunKey) ?? 0;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    if (DateTime.now().difference(last).inHours < 24) return;
    try {
      await _cleanup();
      await prefs.setInt(_lastRunKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Offline or transient error — try again next launch.
    }
  }

  Future<void> _cleanup() async {
    final now = DateTime.now();
    await _expire(
      column: 'photo_path',
      bucket: MediaService.photosBucket,
      cutoff: now.subtract(const Duration(days: _photoMaxAgeDays)),
    );
    await _expire(
      column: 'voice_path',
      bucket: MediaService.voiceBucket,
      cutoff: now.subtract(const Duration(days: _voiceMaxAgeDays)),
    );
  }

  Future<void> _expire({required String column, required String bucket, required DateTime cutoff}) async {
    final rows = await client
        .from('tt_orders')
        .select('id,$column,created_at')
        .eq('shop_id', shopId)
        .not(column, 'is', null)
        .lt('created_at', cutoff.toIso8601String());

    for (final row in (rows as List)) {
      final map = Map<String, dynamic>.from(row as Map);
      final path = map[column] as String?;
      if (path == null || path.isEmpty) continue;
      try {
        await client.storage.from(bucket).remove([path]); // delete the file only
      } catch (_) {/* file may already be gone */}
      // Keep the order; just clear the media reference.
      await client.from('tt_orders').update({column: null}).eq('id', map['id'] as String);
    }
  }
}

/// Runs the daily retention sweep once the shop is known. Watch this provider
/// somewhere that's always mounted (the Home screen) to kick it off.
final retentionProvider = FutureProvider<void>((ref) async {
  final shopId = ref.watch(shopIdProvider);
  if (shopId == null) return;
  await RetentionService(ref.watch(supabaseClientProvider), shopId).runIfDue();
});
