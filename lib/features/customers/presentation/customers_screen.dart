import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widgets/customer_card.dart';
import '../../../core/services/phone_service.dart';
import '../data/customers_repository.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider).where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.phone.replaceAll(' ', '').contains(q.replaceAll(' ', ''));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => context.push('/new-order'),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search by name or phone',
                ),
              ),
            ),
            Expanded(
              child: customers.isEmpty
                  ? const Center(child: Text('No customers found'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: customers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        final stats = ref.watch(customerStatsProvider(customer.id));
                        return CustomerCard(
                          customer: customer,
                          stats: stats,
                          onTap: () => context.push('/customer/${customer.id}'),
                          onCall: () => callNumber(context, customer.phone),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
