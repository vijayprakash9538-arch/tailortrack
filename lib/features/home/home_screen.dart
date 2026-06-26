import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets/brand.dart';
import '../../common/widgets/order_card.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/summary_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../insights/presentation/insights_providers.dart';
import '../orders/data/orders_repository.dart';
import '../orders/domain/order_enums.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  ({String text, String emoji}) _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return (text: 'Good Morning', emoji: '👋');
    if (hour < 17) return (text: 'Good Afternoon', emoji: '☀️');
    return (text: 'Good Evening', emoji: '🌙');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final todaysOrders = ref.watch(todaysOrdersProvider);
    final readyOrders = ref.watch(readyOrdersProvider);
    final pendingOrders = ref.watch(pendingOrdersProvider);
    final pendingPayments = ref.watch(pendingPaymentsTotalProvider);
    final recentOrders = ref.watch(recentOrdersProvider).take(5).toList();
    final schedule = ref.watch(deliveryScheduleProvider);
    final overdueCount = orders.where((o) => o.effectiveStatus == OrderStatus.overdue).length;
    final greeting = _greeting();

    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => context.push('/new-order'),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${greeting.text} ${greeting.emoji}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                          ),
                          child: IconButton(
                            iconSize: 19,
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_none_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const BrandLockup(logoSize: 42, fontSize: 27),
                    const SizedBox(height: 6),
                    Text(
                      'Manage your tailoring business effortlessly.',
                      style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            ),
            // Overdue alert
            if (overdueCount > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _OverdueBanner(count: overdueCount, onTap: () => context.go('/orders')),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                delegate: SliverChildListDelegate([
                  SummaryCard(icon: Icons.calendar_today_rounded, iconColor: AppColors.primary, value: '${todaysOrders.length}', label: "Today's Orders", onTap: () => context.go('/orders')),
                  SummaryCard(icon: Icons.local_shipping_rounded, iconColor: AppColors.statusReady, value: '${readyOrders.length}', label: 'Ready for Delivery', onTap: () => context.go('/orders')),
                  SummaryCard(icon: Icons.hourglass_bottom_rounded, iconColor: AppColors.statusPending, value: '${pendingOrders.length}', label: 'Pending Orders', onTap: () => context.go('/orders')),
                  SummaryCard(icon: Icons.currency_rupee_rounded, iconColor: AppColors.statusStitching, value: '₹${pendingPayments.toStringAsFixed(0)}', label: 'Pending Payments', onTap: () => context.go('/insights')),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/new-order'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Order'),
                  ),
                ),
              ),
            ),
            // Today's delivery schedule
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: "Today's Schedule"),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _ScheduleChip(icon: Icons.wb_sunny_outlined, color: AppColors.statusPending, label: 'Morning', count: schedule.morning)),
                        const SizedBox(width: 10),
                        Expanded(child: _ScheduleChip(icon: Icons.light_mode_rounded, color: AppColors.statusStitching, label: 'Afternoon', count: schedule.afternoon)),
                        const SizedBox(width: 10),
                        Expanded(child: _ScheduleChip(icon: Icons.nights_stay_rounded, color: AppColors.statusDelivered, label: 'Evening', count: schedule.evening)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(title: 'Recent Orders', actionLabel: 'View All', onAction: () => context.go('/orders')),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList.separated(
                itemCount: recentOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = recentOrders[index];
                  return OrderCard(order: order, onTap: () => context.push('/order/${order.id}'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _OverdueBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.statusOverdue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.statusOverdue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.statusOverdue, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count order${count > 1 ? 's are' : ' is'} overdue — needs attention',
                style: const TextStyle(color: AppColors.statusOverdue, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.statusOverdue, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  const _ScheduleChip({required this.icon, required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text('$count', style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
