import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widgets/order_card.dart';
import '../../../common/widgets/section_header.dart';
import '../../../core/services/phone_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../orders/data/orders_repository.dart';
import '../data/customers_repository.dart';

class CustomerProfileScreen extends ConsumerWidget {
  final String customerId;
  const CustomerProfileScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);
    final matches = customers.where((c) => c.id == customerId);
    final customer = matches.isEmpty ? null : matches.first;
    if (customer == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Customer not found')));
    }

    final stats = ref.watch(customerStatsProvider(customerId));
    final orders = ref.watch(ordersProvider).where((o) => o.customerId == customerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final measurement = customer.lastMeasurement;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            tooltip: 'Call customer',
            onPressed: () => callNumber(context, customer.phone),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit customer',
            onPressed: () => context.push('/edit-customer/${customer.id}'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  Text(customer.phone, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _StatTile(label: 'Total Orders', value: '${stats.totalOrders}')),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(label: 'Total Spent', value: '₹${stats.totalSpent.toStringAsFixed(0)}')),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(label: 'Pending', value: '₹${stats.pendingBalance.toStringAsFixed(0)}', highlight: stats.pendingBalance > 0)),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/new-order', extra: customer.id),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Repeat Order'),
          ),
          if (measurement?.notes != null && measurement!.notes!.isNotEmpty) ...[
            const SizedBox(height: 28),
            SectionHeader(title: 'Measurements', actionLabel: 'Edit', onAction: () => context.push('/edit-customer/${customer.id}')),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
              ),
              child: Text(measurement.notes!, style: const TextStyle(height: 1.5)),
            ),
          ],
          const SizedBox(height: 28),
          SectionHeader(title: 'Recent Orders', actionLabel: orders.length > 3 ? 'View All' : null),
          const SizedBox(height: 10),
          ...orders.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OrderCard(order: o, showFinancials: true, onTap: () => context.push('/order/${o.id}')),
              )),
        ],
      ),
    );
  }

}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _StatTile({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: highlight ? AppColors.statusOverdue : null)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
