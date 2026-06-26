import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/accordion_section.dart';
import '../../../common/widgets/section_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../customers/data/customers_repository.dart';
import '../../orders/data/orders_repository.dart';
import 'insights_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(businessHealthProvider);
    final pendingOrders = ref.watch(ordersProvider).where((o) => o.balance > 0).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));
    final topCustomers = ref.watch(topCustomersProvider).take(5).toList();
    final dressTypes = ref.watch(dressTypeAnalyticsProvider);
    final trend = ref.watch(monthlyTrendProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: const [Padding(padding: EdgeInsets.only(right: 12), child: _MonthFilter())],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _BusinessHealthCard(health: health),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Monthly Collected'),
          const SizedBox(height: 12),
          _IncomeTrendChart(trend: trend),
          const SizedBox(height: 16),
          AccordionSection(
            title: 'Pending Payments',
            icon: Icons.hourglass_bottom_rounded,
            trailingSummary: _CountPill(text: '${pendingOrders.length}', color: AppColors.statusOverdue),
            child: pendingOrders.isEmpty
                ? const _EmptyHint(text: 'No pending payments 🎉')
                : Column(
                    children: pendingOrders.take(8).map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PendingPaymentRow(
                            name: o.customerName,
                            dressType: o.dressType,
                            amount: o.balance,
                            onMarkPaid: () => ref.read(ordersProvider.notifier).updateOrder(o.copyWith(advance: o.totalAmount)),
                            onTap: () => context.push('/order/${o.id}'),
                          ),
                        )).toList(),
                  ),
          ),
          const SizedBox(height: 12),
          AccordionSection(
            title: 'Top Customers',
            icon: Icons.emoji_events_outlined,
            child: Column(
              children: topCustomers.asMap().entries.map((entry) {
                final stats = ref.watch(customerStatsProvider(entry.value.id));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TopCustomerRow(rank: entry.key + 1, name: entry.value.name, orders: stats.totalOrders, spent: stats.totalSpent),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Dress Type Analytics'),
          const SizedBox(height: 12),
          _DressTypeDonut(dressTypes: dressTypes),
        ],
      ),
    );
  }
}

class _MonthFilter extends ConsumerWidget {
  const _MonthFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = ref.watch(availableMonthsProvider);
    final selected = ref.watch(insightsMonthProvider);
    String label(DateTime? m) => m == null ? 'All Time' : DateFormat('MMM yyyy').format(m);
    return DropdownButtonHideUnderline(
      child: DropdownButton<DateTime?>(
        value: selected,
        isDense: true,
        borderRadius: BorderRadius.circular(14),
        icon: const Icon(Icons.expand_more_rounded, size: 18),
        items: months.map((m) => DropdownMenuItem(value: m, child: Text(label(m), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
        onChanged: (m) => ref.read(insightsMonthProvider.notifier).state = m,
      ),
    );
  }
}

class _BusinessHealthCard extends StatelessWidget {
  final BusinessHealth health;
  const _BusinessHealthCard({required this.health});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Business Health', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _healthStat('${health.totalOrders}', 'Orders'),
              _healthStat('₹${health.orderValue.toStringAsFixed(0)}', 'Order Value'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _healthStat('₹${health.collected.toStringAsFixed(0)}', 'Collected'),
              _healthStat('₹${health.pending.toStringAsFixed(0)}', 'Pending'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _healthStat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String text;
  final Color color;
  const _CountPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _IncomeTrendChart extends StatelessWidget {
  final List<MonthlyEarning> trend;
  const _IncomeTrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final maxValue = trend.fold(0.0, (m, e) => e.collected > m ? e.collected : m);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: BarChart(
        BarChartData(
          maxY: safeMax * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem('₹${rod.toY.toStringAsFixed(0)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 6), child: Text(trend[i].label, style: const TextStyle(fontSize: 11)));
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < trend.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: trend[i].collected,
                    color: i == trend.length - 1 ? AppColors.primary : AppColors.primary.withOpacity(0.35),
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PendingPaymentRow extends StatelessWidget {
  final String name;
  final String dressType;
  final double amount;
  final VoidCallback onMarkPaid;
  final VoidCallback onTap;
  const _PendingPaymentRow({required this.name, required this.dressType, required this.amount, required this.onMarkPaid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(dressType, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
                ],
              ),
            ),
            Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.statusOverdue)),
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 22),
              tooltip: 'Mark fully paid',
              onPressed: onMarkPaid,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCustomerRow extends StatelessWidget {
  final int rank;
  final String name;
  final int orders;
  final double spent;
  const _TopCustomerRow({required this.rank, required this.name, required this.orders, required this.spent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 13, backgroundColor: AppColors.primaryLight, child: Text('$rank', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('$orders Orders', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
              ],
            ),
          ),
          Text('₹${spent.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DressTypeDonut extends StatelessWidget {
  final List<DressTypeShare> dressTypes;
  const _DressTypeDonut({required this.dressTypes});

  static const _palette = [AppColors.primary, AppColors.statusStitching, AppColors.statusPending, AppColors.statusDelivered, AppColors.statusReady, AppColors.statusOverdue];

  @override
  Widget build(BuildContext context) {
    if (dressTypes.isEmpty) return const _EmptyHint(text: 'No orders in this period');
    final total = dressTypes.fold(0, (s, d) => s + d.count);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 130,
            width: 130,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: [
                  for (var i = 0; i < dressTypes.length; i++)
                    PieChartSectionData(
                      value: dressTypes[i].count.toDouble(),
                      color: _palette[i % _palette.length],
                      title: '',
                      radius: 24,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < dressTypes.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: _palette[i % _palette.length], shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(dressTypes[i].dressType, style: const TextStyle(fontSize: 13))),
                        Text('${((dressTypes[i].count / total) * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
    );
  }
}
