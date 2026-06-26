import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../authentication/data/auth_controller.dart';
import '../../authentication/data/shop_providers.dart';
import '../../customers/domain/customer.dart';
import '../../orders/domain/order.dart';

/// How an imported backup is applied to the current shop.
enum ImportMode { merge, replace }

/// A parsed + validated backup ready to preview/apply.
class BackupData {
  final int customerCount;
  final int orderCount;
  final String? exportedAt;
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> orders;

  BackupData({
    required this.customerCount,
    required this.orderCount,
    required this.exportedAt,
    required this.customers,
    required this.orders,
  });
}

/// Manual backup: export the shop's customers + orders (which carry
/// measurements and payment amounts) to JSON/ZIP, and import them back with
/// validation, preview, and merge-or-replace. Photos and voice notes are
/// intentionally excluded.
class BackupService {
  final SupabaseClient client;
  final String shopId;
  BackupService(this.client, this.shopId);

  static const _appTag = 'TailorTrack';
  static const _version = 1;

  Map<String, dynamic> buildBackup({Shop? shop, required List<Customer> customers, required List<Order> orders}) {
    return {
      'app': _appTag,
      'version': _version,
      'exported_at': DateTime.now().toIso8601String(),
      'shop': shop == null ? null : {'shop_name': shop.shopName, 'owner_name': shop.ownerName, 'email': shop.email},
      'customers': customers
          .map((c) => {'id': c.id, 'name': c.name, 'phone': c.phone, 'measurement_notes': c.lastMeasurement?.notes})
          .toList(),
      'orders': orders.map((o) {
        final m = o.toDbMap(shopId);
        // Exclude media + shop scoping from the portable file.
        m.remove('shop_id');
        m.remove('photo_path');
        m.remove('voice_path');
        return m;
      }).toList(),
    };
  }

  Uint8List encodeJson(Map<String, dynamic> backup) {
    return Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(backup)));
  }

  Uint8List encodeZip(Map<String, dynamic> backup) {
    final jsonBytes = encodeJson(backup);
    final archive = Archive()..addFile(ArchiveFile('tailortrack_backup.json', jsonBytes.length, jsonBytes));
    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  /// Parses and validates a picked file (JSON or ZIP). Throws [FormatException]
  /// with a friendly message if the file isn't a valid TailorTrack backup.
  BackupData parse(Uint8List bytes, String fileName) {
    String text;
    final isZip = fileName.toLowerCase().endsWith('.zip') || (bytes.length > 1 && bytes[0] == 0x50 && bytes[1] == 0x4B);
    if (isZip) {
      final archive = ZipDecoder().decodeBytes(bytes);
      final jsonFile = archive.files.firstWhere(
        (f) => f.name.toLowerCase().endsWith('.json'),
        orElse: () => throw const FormatException('No backup JSON found inside the ZIP.'),
      );
      text = utf8.decode(jsonFile.content as List<int>);
    } else {
      text = utf8.decode(bytes);
    }

    final Map<String, dynamic> map;
    try {
      map = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('This file isn\'t valid JSON.');
    }
    if (map['app'] != _appTag) {
      throw const FormatException('This doesn\'t look like a TailorTrack backup.');
    }
    final customers = (map['customers'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final orders = (map['orders'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    return BackupData(
      customerCount: customers.length,
      orderCount: orders.length,
      exportedAt: map['exported_at'] as String?,
      customers: customers,
      orders: orders,
    );
  }

  /// Applies a parsed backup. In [ImportMode.replace] the shop's existing
  /// customers/orders are cleared first. Media columns are left null.
  Future<void> apply(BackupData data, ImportMode mode) async {
    if (mode == ImportMode.replace) {
      await client.from('tt_orders').delete().eq('shop_id', shopId);
      await client.from('tt_customers').delete().eq('shop_id', shopId);
    }

    if (data.customers.isNotEmpty) {
      final rows = data.customers.map((c) => {...c, 'shop_id': shopId}).toList();
      await client.from('tt_customers').upsert(rows);
    }
    if (data.orders.isNotEmpty) {
      final rows = data.orders.map((o) => {...o, 'shop_id': shopId, 'photo_path': null, 'voice_path': null}).toList();
      await client.from('tt_orders').upsert(rows);
    }
  }
}

final backupServiceProvider = Provider<BackupService?>((ref) {
  final shopId = ref.watch(shopIdProvider);
  if (shopId == null) return null;
  return BackupService(ref.watch(supabaseClientProvider), shopId);
});
