import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/order_card.dart';
import '../../../common/widgets/status_picker_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';
import '../domain/order_enums.dart';
import 'order_status_actions.dart';

/// The three top-level views:
/// - Upcoming: active (non-delivered) orders grouped by how soon they're due.
/// - All: every active order in one list, filterable by status.
/// - Done: completed (delivered) orders.
enum _OrdersView { upcoming, all, delivered }

const _statusFilters = ['All', 'Pending', 'Stitching', 'Ready', 'Overdue'];

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _query = '';
  String _statusFilter = 'All';
  _OrdersView _view = _OrdersView.upcoming;
  DateTimeRange? _range;

  bool _matchesSearch(Order o) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return o.customerName.toLowerCase().contains(q) ||
        o.phone.replaceAll(' ', '').contains(q.replaceAll(' ', ''));
  }

  bool _matchesRange(Order o) {
    if (_range == null) return true;
    final d = DateTime(o.deliveryDate.year, o.deliveryDate.month, o.deliveryDate.day);
    final start = DateTime(_range!.start.year, _range!.start.month, _range!.start.day);
    final end = DateTime(_range!.end.year, _range!.end.month, _range!.end.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  Future<void> _updateStatus(Order order) async {
    final picked = await showStatusPicker(context, current: order.status, title: '${order.customerName} · ${order.dressType}');
    if (picked != null && mounted) {
      await applyOrderStatus(context, ref, order, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final base = orders.where((o) => _matchesSearch(o) && _matchesRange(o)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: Icon(_range == null ? Icons.date_range_outlined : Icons.event_busy_rounded),
            tooltip: _range == null ? 'Filter by delivery date' : 'Clear date filter',
            onPressed: () async {
              if (_range != null) {
                setState(() => _range = null);
                return;
              }
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _range = picked);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => context.push('/new-order'),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search by name or phone',
                ),
              ),
            ),
            // View segmented control — labels only so "Upcoming" fits on phones.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<_OrdersView>(
                segments: const [
                  ButtonSegment(value: _OrdersView.upcoming, label: Text('Upcoming')),
                  ButtonSegment(value: _OrdersView.all, label: Text('All')),
                  ButtonSegment(value: _OrdersView.delivered, label: Text('Done')),
                ],
                selected: {_view},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _view = s.first),
                style: const ButtonStyle(
                  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                ),
              ),
            ),
            if (_range != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text('${DateFormat('d MMM').format(_range!.start)} – ${DateFormat('d MMM').format(_range!.end)}'),
                    onDeleted: () => setState(() => _range = null),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(child: _buildBody(base)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Order> base) {
    switch (_view) {
      case _OrdersView.upcoming:
        return _UpcomingView(orders: base, onTapOrder: (o) => context.push('/order/${o.id}'), onStatusTap: _updateStatus);
      case _OrdersView.all:
        return _AllView(
          orders: base,
          statusFilter: _statusFilter,
          onStatusFilterChange: (f) => setState(() => _statusFilter = f),
          onTapOrder: (o) => context.push('/order/${o.id}'),
          onStatusTap: _updateStatus,
        );
      case _OrdersView.delivered:
        final delivered = base.where((o) => o.status == OrderStatus.delivered).toList()
          ..sort((a, b) => b.deliveryDate.compareTo(a.deliveryDate));
        if (delivered.isEmpty) return const _Empty(text: 'No completed orders yet');
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            _CappedOrderList(
              orders: delivered,
              cap: 12,
              onTapOrder: (o) => context.push('/order/${o.id}'),
              onStatusTap: _updateStatus,
            ),
          ],
        );
    }
  }
}

/// Groups active orders into time buckets so the tailor sees what's overdue
/// and what's due this week without scanning a flat list. Each bucket caps
/// its list and offers a "View all" expander.
class _UpcomingView extends StatelessWidget {
  final List<Order> orders;
  final void Function(Order) onTapOrder;
  final Future<void> Function(Order) onStatusTap;

  const _UpcomingView({required this.orders, required this.onTapOrder, required this.onStatusTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int dayDiff(DateTime d) => DateTime(d.year, d.month, d.day).difference(today).inDays;

    final active = orders.where((o) => o.status != OrderStatus.delivered).toList()
      ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

    if (active.isEmpty) return const _Empty(text: 'No pending orders 🎉');

    final overdue = <Order>[];
    final dueToday = <Order>[];
    final tomorrow = <Order>[];
    final thisWeek = <Order>[];
    final later = <Order>[];
    for (final o in active) {
      final diff = dayDiff(o.deliveryDate);
      if (diff < 0) {
        overdue.add(o);
      } else if (diff == 0) {
        dueToday.add(o);
      } else if (diff == 1) {
        tomorrow.add(o);
      } else if (diff <= 7) {
        thisWeek.add(o);
      } else {
        later.add(o);
      }
    }

    final sections = <Widget>[];
    void addSection(String title, List<Order> items, Color color, IconData icon, int cap) {
      if (items.isEmpty) return;
      sections.add(_SectionHeader(title: title, count: items.length, color: color, icon: icon));
      sections.add(_CappedOrderList(orders: items, cap: cap, onTapOrder: onTapOrder, onStatusTap: onStatusTap));
      sections.add(const SizedBox(height: 10));
    }

    addSection('Overdue', overdue, AppColors.statusOverdue, Icons.warning_amber_rounded, 5);
    addSection('Today', dueToday, AppColors.primary, Icons.today_rounded, 6);
    addSection('Tomorrow', tomorrow, AppColors.statusStitching, Icons.event_rounded, 5);
    addSection('This Week', thisWeek, AppColors.statusPending, Icons.date_range_rounded, 5);
    addSection('Later', later, AppColors.textSecondary, Icons.schedule_rounded, 4);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: sections,
    );
  }
}

class _AllView extends StatelessWidget {
  final List<Order> orders;
  final String statusFilter;
  final ValueChanged<String> onStatusFilterChange;
  final void Function(Order) onTapOrder;
  final Future<void> Function(Order) onStatusTap;

  const _AllView({
    required this.orders,
    required this.statusFilter,
    required this.onStatusFilterChange,
    required this.onTapOrder,
    required this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    // "All" = active orders only (completed live under the Done tab).
    final active = orders.where((o) => o.status != OrderStatus.delivered).toList();
    final filtered = active.where((o) {
      if (statusFilter == 'All') return true;
      return o.effectiveStatus.label == statusFilter;
    }).toList()
      ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

    return Column(
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _statusFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final label = _statusFilters[i];
              return ChoiceChip(
                label: Text(label),
                selected: statusFilter == label,
                onSelected: (_) => onStatusFilterChange(label),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: filtered.isEmpty
              ? const _Empty(text: 'No orders found')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    _CappedOrderList(orders: filtered, cap: 15, onTapOrder: onTapOrder, onStatusTap: onStatusTap),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Renders up to [cap] order cards, then a "View all (N more)" button that
/// reveals the rest (and a "Show less" to collapse again). Keeps long lists
/// scannable without endless scrolling.
class _CappedOrderList extends StatefulWidget {
  final List<Order> orders;
  final int cap;
  final void Function(Order) onTapOrder;
  final Future<void> Function(Order) onStatusTap;

  const _CappedOrderList({required this.orders, required this.cap, required this.onTapOrder, required this.onStatusTap});

  @override
  State<_CappedOrderList> createState() => _CappedOrderListState();
}

class _CappedOrderListState extends State<_CappedOrderList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final all = widget.orders;
    final visible = _expanded ? all : all.take(widget.cap).toList();
    final hidden = all.length - visible.length;

    return Column(
      children: [
        for (final o in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OrderCard(
              order: o,
              showFinancials: true,
              showOrderedDate: true,
              onTap: () => widget.onTapOrder(o),
              onStatusTap: () => widget.onStatusTap(o),
            ),
          ),
        if (all.length > widget.cap)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18),
              label: Text(_expanded ? 'Show less' : 'View all ($hidden more)'),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  const _SectionHeader({required this.title, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
    );
  }
}
