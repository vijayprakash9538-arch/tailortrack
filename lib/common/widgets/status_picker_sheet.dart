import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../features/orders/domain/order_enums.dart';

/// Compact bottom sheet for changing an order's progress in one tap —
/// reused by the Orders list (inline) and the Order Details screen so the
/// tailor never has to dig through a form just to mark something Ready.
///
/// Returns the chosen [OrderStatus], or null if dismissed.
Future<OrderStatus?> showStatusPicker(
  BuildContext context, {
  required OrderStatus current,
  String? title,
}) {
  return showModalBottomSheet<OrderStatus>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerTheme.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title ?? 'Update Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...OrderStatusX.workflow.map((status) {
                final selected = status == current;
                final color = AppColors.statusColor(status.name);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(status),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? color.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        border: Border.all(
                          color: selected ? color : (Theme.of(context).dividerTheme.color ?? Colors.transparent),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                            child: Icon(status.icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(status.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const Spacer(),
                          if (selected) Icon(Icons.check_rounded, color: color, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
