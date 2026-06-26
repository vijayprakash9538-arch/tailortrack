import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../features/orders/domain/order.dart';

/// Result of the delivery settlement dialog: the new total advance/collected
/// amount for the order (existing advance + amount received at delivery).
class SettlementResult {
  final double newAdvance;
  const SettlementResult(this.newAdvance);
}

/// Shown when an order is marked **Delivered** while it still has a pending
/// balance. Lets the tailor record how much was collected at handover —
/// "Fully Paid" settles the whole balance, or they can enter a partial
/// amount and leave the rest pending.
///
/// Returns a [SettlementResult] to apply, or null if cancelled (in which
/// case the caller should not change the status).
Future<SettlementResult?> showSettlePaymentDialog(BuildContext context, Order order) {
  final controller = TextEditingController(text: order.balance.toStringAsFixed(0));
  return showDialog<SettlementResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final received = double.tryParse(controller.text) ?? 0;
          final remaining = (order.balance - received).clamp(0, order.balance).toDouble();
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
            title: const Text('Collect Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(context, 'Total Amount', order.totalAmount),
                _row(context, 'Already Paid', order.advance),
                _row(context, 'Pending Balance', order.balance, highlight: order.balance > 0),
                const SizedBox(height: 16),
                const Text('Amount received now', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(prefixText: '₹ '),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() => controller.text = order.balance.toStringAsFixed(0)),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
                      child: const Text('Fully Paid'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => setState(() => controller.text = '0'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
                      child: const Text('Still Pending'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: remaining > 0 ? AppColors.statusOverdue.withOpacity(0.1) : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    remaining > 0 ? 'Remaining balance: ₹${remaining.toStringAsFixed(0)}' : 'Order fully settled ✓',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: remaining > 0 ? AppColors.statusOverdue : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final collectedNow = (double.tryParse(controller.text) ?? 0).clamp(0, order.balance).toDouble();
                  Navigator.of(context).pop(SettlementResult(order.advance + collectedNow));
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                child: const Text('Mark Delivered'),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _row(BuildContext context, String label, double amount, {bool highlight = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.w700, color: highlight ? AppColors.statusOverdue : null),
        ),
      ],
    ),
  );
}
