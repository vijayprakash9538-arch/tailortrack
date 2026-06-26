import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../features/customers/data/customers_repository.dart';
import '../../features/customers/domain/customer.dart';
import 'pressable_scale.dart';

/// Customer summary card with live order count / pending balance pulled
/// from [customerStatsProvider] — never a stored snapshot.
class CustomerCard extends StatelessWidget {
  final Customer customer;
  final CustomerStats stats;
  final VoidCallback? onTap;
  final VoidCallback? onCall;

  const CustomerCard({super.key, required this.customer, required this.stats, this.onTap, this.onCall});

  @override
  Widget build(BuildContext context) {
    final initial = customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?';
    return PressableScale(
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              child: Text(initial, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    customer.phone,
                    style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.totalOrders} Orders',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${stats.pendingBalance.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: stats.pendingBalance > 0 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stats.pendingBalance > 0 ? 'Pending' : 'Settled',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                ),
              ],
            ),
            if (onCall != null)
              IconButton(
                icon: const Icon(Icons.call_rounded, size: 18),
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'Call ${customer.name}',
                onPressed: onCall,
              )
            else
              const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4)),
          ],
        ),
      ),
      ),
    );
  }
}
