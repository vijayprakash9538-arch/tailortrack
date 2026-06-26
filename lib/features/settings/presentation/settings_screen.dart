import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/confirm_dialog.dart';
import '../../../core/theme/app_colors.dart';
import '../../authentication/data/auth_controller.dart';
import '../../authentication/data/shop_providers.dart';
import '../../customers/data/customers_repository.dart';
import '../../orders/data/orders_repository.dart';
import '../data/backup_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _export({required bool zip}) async {
    final service = ref.read(backupServiceProvider);
    if (service == null) return;
    setState(() => _busy = true);
    try {
      final backup = service.buildBackup(
        shop: ref.read(currentShopProvider).asData?.value,
        customers: ref.read(customersProvider),
        orders: ref.read(ordersProvider),
      );
      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      if (zip) {
        await FileSaver.instance.saveFile(name: 'tailortrack_backup_$stamp', bytes: service.encodeZip(backup), ext: 'zip', mimeType: MimeType.zip);
      } else {
        await FileSaver.instance.saveFile(name: 'tailortrack_backup_$stamp', bytes: service.encodeJson(backup), ext: 'json', mimeType: MimeType.json);
      }
      _toast('Backup exported');
    } catch (e) {
      _toast('Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final service = ref.read(backupServiceProvider);
    if (service == null) return;
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json', 'zip'], withData: true);
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      _toast('Could not read the file.');
      return;
    }

    BackupData data;
    try {
      data = service.parse(bytes, file.name);
    } catch (e) {
      _toast(e is FormatException ? e.message : 'Invalid backup file.');
      return;
    }
    if (!mounted) return;

    final mode = await _chooseImportMode(data);
    if (mode == null) return;

    setState(() => _busy = true);
    try {
      await service.apply(data, mode);
      ref.invalidate(ordersProvider);
      ref.invalidate(customersProvider);
      _toast('Imported ${data.customerCount} customers and ${data.orderCount} orders');
    } catch (e) {
      _toast('Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Preview + choose Merge or Replace.
  Future<ImportMode?> _chooseImportMode(BackupData data) {
    final when = data.exportedAt == null ? '' : ' · exported ${DateFormat('d MMM yyyy').format(DateTime.parse(data.exportedAt!))}';
    return showDialog<ImportMode>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Import backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This file contains:$when', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text('• ${data.customerCount} customers', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('• ${data.orderCount} orders', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text('Merge keeps your current data and adds/updates from the file.\nReplace deletes your current data first.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ImportMode.merge), child: const Text('Merge')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ImportMode.replace),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusOverdue, minimumSize: const Size(0, 44)),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(supabaseClientProvider).auth.currentUser?.email ?? '—';
    final shop = ref.watch(currentShopProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _sectionTitle(context, 'Account'),
          _card(context, [
            _row(context, Icons.storefront_outlined, 'Shop', shop?.shopName ?? '—'),
            const Divider(height: 1),
            _row(context, Icons.mail_outline_rounded, 'Email', email),
            if (shop?.ownerName != null) ...[
              const Divider(height: 1),
              _row(context, Icons.person_outline_rounded, 'Owner', shop!.ownerName!),
            ],
          ]),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await confirmDelete(
                context,
                title: 'Sign out?',
                message: 'You can sign back in anytime with your email and password.',
                confirmLabel: 'Sign out',
              );
              if (ok) await ref.read(authControllerProvider).signOut();
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.statusOverdue, side: const BorderSide(color: AppColors.statusOverdue)),
          ),
          const SizedBox(height: 28),
          _sectionTitle(context, 'Backup & Restore'),
          _card(context, [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Automatic Cloud Backup', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          'Your customers, orders, measurements and payments sync to the cloud automatically and restore on any device you sign in to.',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.65)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            'Manual backup (excludes photos & voice notes)',
            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _export(zip: false),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Export JSON'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _export(zip: true),
                  icon: const Icon(Icons.folder_zip_outlined, size: 18),
                  label: const Text('Export ZIP'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _busy ? null : _import,
            icon: _busy
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Import Backup'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(t, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      );

  Widget _card(BuildContext context, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );

  Widget _row(BuildContext context, IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
            Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
