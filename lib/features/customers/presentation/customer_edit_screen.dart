import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widgets/labeled_field.dart';
import '../../customers/domain/measurement.dart';
import '../data/customers_repository.dart';

/// Edit a customer's name, phone and saved measurements. The measurements
/// edited here become the customer's [Customer.lastMeasurement], which is
/// what auto-fills future repeat orders.
class CustomerEditScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerEditScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends ConsumerState<CustomerEditScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _measure = TextEditingController();

  @override
  void initState() {
    super.initState();
    final matches = ref.read(customersProvider).where((c) => c.id == widget.customerId);
    if (matches.isNotEmpty) {
      final c = matches.first;
      _name.text = c.name;
      _phone.text = c.phone;
      _measure.text = c.lastMeasurement?.notes ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _measure.dispose();
    super.dispose();
  }

  void _save() {
    final matches = ref.read(customersProvider).where((c) => c.id == widget.customerId);
    if (matches.isEmpty) return;
    final text = _measure.text.trim();
    final updated = matches.first.copyWith(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      lastMeasurement: text.isEmpty ? null : Measurement(notes: text),
    );
    ref.read(customersProvider.notifier).updateCustomer(updated);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: const Text('Edit Customer'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          LabeledField(
            label: 'Customer Name',
            child: TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded)),
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Mobile Number',
            child: TextField(
              controller: _phone,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.call_outlined)),
            ),
          ),
          const SizedBox(height: 24),
          LabeledField(
            label: 'Measurements',
            child: TextField(
              controller: _measure,
              maxLines: 6,
              minLines: 4,
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                hintText: 'Type measurements freely, e.g.\nChest 34, Waist 28, Shoulder 14\nPant: Waist 30, Length 38',
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _name.text.trim().isEmpty || _phone.text.trim().isEmpty ? null : _save,
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
