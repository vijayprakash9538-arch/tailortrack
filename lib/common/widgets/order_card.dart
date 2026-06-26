import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_radius.dart';
import '../../features/orders/domain/order.dart';
import '../../features/orders/domain/order_enums.dart';
import 'pressable_scale.dart';
import 'status_badge.dart';

/// Order summary card reused on Home ("Recent Orders") and the Orders list.
/// [showFinancials] toggles the advance/balance row, which Home omits to
/// stay compact.
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final bool showFinancials;

  /// When provided, the status badge becomes a tappable "update progress"
  /// control so the tailor can advance an order without opening details.
  final VoidCallback? onStatusTap;

  /// Shows the date the order was placed ("Ordered 25 Jun") under the row.
  final bool showOrderedDate;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.showFinancials = false,
    this.onStatusTap,
    this.showOrderedDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final initial = order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : '?';
    return PressableScale(
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              child: Text(initial, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(order.customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                      ),
                      Text('₹${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Dress type · delivery date/time   +   status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${order.dressType}  ·  ${DateFormat('d MMM').format(order.deliveryDate)} ${order.expectedDeliveryTime.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (onStatusTap != null)
                        InkWell(
                          onTap: onStatusTap,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusBadge(status: order.effectiveStatus),
                              Icon(Icons.expand_more_rounded, size: 15, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                            ],
                          ),
                        )
                      else
                        StatusBadge(status: order.effectiveStatus),
                    ],
                  ),
                  if (showFinancials) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _financialChip(context, 'Adv', order.advance),
                        const SizedBox(width: 10),
                        _financialChip(context, 'Bal', order.balance, highlight: order.balance > 0),
                        if (showOrderedDate) ...[
                          const Spacer(),
                          Text(
                            'Ordered ${DateFormat('d MMM').format(order.createdAt)}',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.45)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _financialChip(BuildContext context, String label, double amount, {bool highlight = false}) {
    return Text(
      '$label: ₹${amount.toStringAsFixed(0)}',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: highlight ? Theme.of(context).colorScheme.error : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
      ),
    );
  }
}
