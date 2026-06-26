import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/status_badge.dart';
import '../../../core/services/phone_service.dart';
import '../../../core/theme/app_colors.dart';
import '../data/orders_repository.dart';
import '../domain/order_enums.dart';
import 'order_status_actions.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final matches = orders.where((o) => o.id == orderId);
    final order = matches.isEmpty ? null : matches.first;

    if (order == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Order not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(order.customerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            tooltip: 'Call customer',
            onPressed: () => callNumber(context, order.phone),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit order',
            onPressed: () => context.push('/edit-order/${order.id}'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              Text(order.dressType, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              StatusBadge(status: order.effectiveStatus),
            ],
          ),
          const SizedBox(height: 4),
          Text(order.phone, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
          const SizedBox(height: 20),
          _DetailCard(children: [
            _row('Delivery Date', DateFormat('d MMM yyyy').format(order.deliveryDate)),
            _row('Expected Time', order.expectedDeliveryTime.label),
            _row('Total Amount', '₹${order.totalAmount.toStringAsFixed(0)}'),
            _row('Advance Paid', '₹${order.advance.toStringAsFixed(0)}'),
            _row('Balance', '₹${order.balance.toStringAsFixed(0)}', highlight: order.balance > 0),
          ]),
          if (order.measurement?.notes != null && order.measurement!.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Measurements', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _DetailCard(children: [
              Text(order.measurement!.notes!, style: const TextStyle(height: 1.5)),
            ]),
          ],
          if (order.notes != null) ...[
            const SizedBox(height: 16),
            Text('Notes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(order.notes!),
          ],
          if (order.photoPath != null) ...[
            const SizedBox(height: 16),
            Text('Photo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: kIsWeb
                  ? Image.network(order.photoPath!, height: 220, width: double.infinity, fit: BoxFit.cover)
                  : Image.file(File(order.photoPath!), height: 220, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 24),
          Text('Update Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: OrderStatusX.workflow
                .map((s) => ChoiceChip(
                      label: Text(s.label),
                      selected: order.status == s,
                      onSelected: (_) => applyOrderStatus(context, ref, order, s),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: highlight ? AppColors.statusOverdue : null),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}
