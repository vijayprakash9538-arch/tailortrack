import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the device's phone dialer pre-filled with [phone]. Strips spaces and
/// formatting so the `tel:` URI is valid. On platforms without a dialer
/// (e.g. desktop web) it shows a brief snackbar instead of failing silently.
Future<void> callNumber(BuildContext context, String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final uri = Uri(scheme: 'tel', path: digits);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text('Could not start a call to $phone')));
    }
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text('Calling isn\'t supported on this device · $phone')));
  }
}
