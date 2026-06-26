import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/settle_payment_dialog.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';
import '../domain/order_enums.dart';

/// Single place that applies an order status change. When moving to
/// **Delivered** with an outstanding balance it first prompts the tailor to
/// collect/settle payment, so an order can't be silently delivered while
/// still showing money owed. Used by both the Orders list and Order Details.
Future<void> applyOrderStatus(
  BuildContext context,
  WidgetRef ref,
  Order order,
  OrderStatus newStatus,
) async {
  if (newStatus == OrderStatus.delivered && order.balance > 0) {
    final result = await showSettlePaymentDialog(context, order);
    if (result == null) return; // cancelled — leave status unchanged
    ref.read(ordersProvider.notifier).updateOrder(
          order.copyWith(advance: result.newAdvance, status: OrderStatus.delivered),
        );
  } else {
    ref.read(ordersProvider.notifier).updateStatus(order.id, newStatus);
  }
}
