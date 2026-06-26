import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../common/widgets/accordion_section.dart';
import '../../../common/widgets/labeled_field.dart';
import '../../../common/widgets/option_picker.dart';
import '../../../common/widgets/voice_note.dart';
import '../../../core/storage/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../customers/data/customers_repository.dart';
import '../../customers/domain/customer.dart';
import '../../customers/domain/measurement.dart';
import '../data/dress_types_provider.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';
import '../domain/order_enums.dart';

/// New Order form. Three modes:
/// - create (default)
/// - repeat: [repeatCustomerId] set — opens in "repeat customer" mode with
///   that customer's details/measurements pre-filled (from Customer Profile).
/// - edit: [editOrderId] set — pre-fills every field from the existing order
///   and saves back to the same id (from Order Details "Edit").
class NewOrderScreen extends ConsumerStatefulWidget {
  final String? repeatCustomerId;
  final String? editOrderId;
  const NewOrderScreen({super.key, this.repeatCustomerId, this.editOrderId});

  bool get isEditing => editOrderId != null;

  @override
  ConsumerState<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends ConsumerState<NewOrderScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _totalController = TextEditingController();
  final _advanceController = TextEditingController();
  final _notesController = TextEditingController();
  // Free-text measurements — one box the tailor fills however they like,
  // editable later. Auto-filled from the customer on a repeat order.
  final _measureController = TextEditingController();

  String? _dressType;
  DateTime _orderDate = DateTime.now(); // when the order was placed; defaults to today
  DateTime? _deliveryDate;
  DeliveryTime? _expectedTime;
  bool _repeatCustomer = false;
  Customer? _selectedCustomer;
  OrderStatus _editingStatus = OrderStatus.pending; // preserved across an edit
  String? _photoPath;
  String? _voicePath;

  @override
  void initState() {
    super.initState();
    if (widget.editOrderId != null) {
      final order = ref.read(ordersProvider).firstWhere((o) => o.id == widget.editOrderId);
      _applyExistingOrder(order);
    } else if (widget.repeatCustomerId != null) {
      _repeatCustomer = true;
      final customer = ref.read(customersProvider).firstWhere((c) => c.id == widget.repeatCustomerId);
      _applyCustomer(customer);
    }
  }

  /// Pre-fills the whole form from an order being edited.
  void _applyExistingOrder(Order order) {
    final matches = ref.read(customersProvider).where((c) => c.id == order.customerId);
    _selectedCustomer = matches.isEmpty ? null : matches.first;
    _nameController.text = order.customerName;
    _phoneController.text = order.phone;
    _dressType = order.dressType;
    _orderDate = order.createdAt;
    _deliveryDate = order.deliveryDate;
    _expectedTime = order.expectedDeliveryTime;
    _editingStatus = order.status;
    _totalController.text = order.totalAmount == 0 ? '' : order.totalAmount.toStringAsFixed(0);
    _advanceController.text = order.advance == 0 ? '' : order.advance.toStringAsFixed(0);
    _notesController.text = order.notes ?? '';
    _measureController.text = order.measurement?.notes ?? '';
    _photoPath = order.photoPath;
    _voicePath = order.voicePath;
  }

  void _applyCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _nameController.text = customer.name;
      _phoneController.text = customer.phone;
      _measureController.text = customer.lastMeasurement?.notes ?? '';
    });
  }

  double get _balance {
    final total = double.tryParse(_totalController.text) ?? 0;
    final advance = double.tryParse(_advanceController.text) ?? 0;
    return total - advance;
  }

  @override
  void dispose() {
    for (final c in [_nameController, _phoneController, _totalController, _advanceController, _notesController, _measureController]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty && _phoneController.text.trim().isNotEmpty && _dressType != null && _deliveryDate != null && _expectedTime != null;

  void _save() {
    final customersNotifier = ref.read(customersProvider.notifier);
    final customer = _selectedCustomer ?? customersNotifier.addOrFind(name: _nameController.text.trim(), phone: _phoneController.text.trim());

    final measureText = _measureController.text.trim();
    final measurement = measureText.isEmpty ? null : Measurement(notes: measureText);
    if (measurement != null) {
      customersNotifier.updateLastMeasurement(customer.id, measurement);
    }

    final order = Order(
      id: widget.editOrderId ?? const Uuid().v4(),
      customerId: customer.id,
      customerName: customer.name,
      phone: customer.phone,
      dressType: _dressType!,
      deliveryDate: _deliveryDate!,
      expectedDeliveryTime: _expectedTime!,
      totalAmount: double.tryParse(_totalController.text) ?? 0,
      advance: double.tryParse(_advanceController.text) ?? 0,
      status: widget.isEditing ? _editingStatus : OrderStatus.pending,
      createdAt: _orderDate,
      measurement: measurement,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      photoPath: _photoPath,
      voicePath: _voicePath,
    );
    if (widget.isEditing) {
      ref.read(ordersProvider.notifier).updateOrder(order);
    } else {
      ref.read(ordersProvider.notifier).addOrder(order);
    }
    context.pop();
  }

  Future<void> _pickDressType() async {
    final types = ref.read(dressTypesProvider);
    final picked = await showOptionPicker(
      context,
      title: 'Dress Type',
      options: types,
      selected: _dressType,
      addNewLabel: 'Add new dress type',
    );
    if (picked == null) return;
    ref.read(dressTypesProvider.notifier).add(picked); // no-op if it already exists
    setState(() => _dressType = picked);
  }

  Future<void> _pickDeliveryTime() async {
    final picked = await showOptionPicker(
      context,
      title: 'Expected Delivery Time',
      options: DeliveryTime.values.map((t) => t.label).toList(),
      selected: _expectedTime?.label,
    );
    if (picked == null) return;
    setState(() => _expectedTime = DeliveryTime.values.firstWhere((t) => t.label == picked));
  }

  Future<void> _pickPhoto() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.statusOverdue),
                title: const Text('Remove Photo', style: TextStyle(color: AppColors.statusOverdue)),
                onTap: () => Navigator.of(context).pop('remove'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'remove') {
      setState(() => _photoPath = null);
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (file != null) setState(() => _photoPath = file.path);
  }

  Widget _photoPreview(String path) {
    final isRemote = !path.startsWith('/') && !path.startsWith('blob:') && !path.startsWith('http') && !path.startsWith('file:');
    if (isRemote) {
      // An already-uploaded photo (editing an order): resolve a signed URL.
      final url = ref.watch(signedUrlProvider((bucket: 'photos', path: path)));
      return url.when(
        data: (u) => Image.network(u, fit: BoxFit.cover),
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => const Center(child: Icon(Icons.broken_image_outlined)),
      );
    }
    if (kIsWeb) return Image.network(path, fit: BoxFit.cover);
    return Image.file(File(path), fit: BoxFit.cover);
  }

  Future<void> _pickCustomer() async {
    final customers = ref.read(customersProvider);
    final picked = await showOptionPicker(
      context,
      title: 'Choose Customer',
      options: customers.map((c) => '${c.name} · ${c.phone}').toList(),
      selected: _selectedCustomer == null ? null : '${_selectedCustomer!.name} · ${_selectedCustomer!.phone}',
    );
    if (picked == null) return;
    final customer = customers.firstWhere((c) => '${c.name} · ${c.phone}' == picked);
    _applyCustomer(customer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: Text(widget.isEditing ? 'Edit Order' : 'New Order'),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _nameController.clear();
              _phoneController.clear();
              _totalController.clear();
              _advanceController.clear();
              _notesController.clear();
              _measureController.clear();
              _dressType = null;
              _orderDate = DateTime.now();
              _deliveryDate = null;
              _expectedTime = null;
              _selectedCustomer = null;
            }),
            child: const Text('Clear'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // Repeat customer toggle (hidden while editing an existing order)
          if (!widget.isEditing) ...[
            _ToggleCard(
              value: _repeatCustomer,
              onChanged: (v) => setState(() {
                _repeatCustomer = v;
                if (!v) _selectedCustomer = null;
              }),
            ),
            const SizedBox(height: 16),
          ],
          if (_repeatCustomer) ...[
            LabeledField(
              label: 'Search Customer',
              child: _PickerField(
                icon: Icons.person_search_rounded,
                hint: 'Choose existing customer',
                value: _selectedCustomer == null ? null : '${_selectedCustomer!.name} · ${_selectedCustomer!.phone}',
                onTap: _pickCustomer,
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            LabeledField(
              label: 'Customer Name *',
              child: TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded), hintText: 'Enter name'),
              ),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Mobile Number *',
              child: TextField(
                controller: _phoneController,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.call_outlined), hintText: '98765 43210'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          LabeledField(
            label: 'Dress Type *',
            child: _PickerField(
              icon: Icons.checkroom_outlined,
              hint: 'Select dress type',
              value: _dressType,
              onTap: _pickDressType,
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Order Date',
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _orderDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _orderDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.event_available_rounded)),
                child: Text(DateFormat('d MMM yyyy').format(_orderDate)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Delivery Date *',
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deliveryDate ?? DateTime.now().add(const Duration(days: 3)),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _deliveryDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today_rounded)),
                child: Text(_deliveryDate == null ? 'Select date' : DateFormat('d MMM yyyy').format(_deliveryDate!)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Expected Delivery Time *',
            child: _PickerField(
              icon: Icons.schedule_rounded,
              hint: 'Morning / Afternoon / Evening',
              value: _expectedTime?.label,
              onTap: _pickDeliveryTime,
            ),
          ),
          const SizedBox(height: 16),
          AccordionSection(
            title: 'Payment',
            icon: Icons.payments_outlined,
            child: Column(
              children: [
                LabeledField(
                  label: 'Total Amount *',
                  child: TextField(
                    controller: _totalController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(prefixText: '₹ '),
                  ),
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: 'Advance (Optional)',
                  child: TextField(
                    controller: _advanceController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(prefixText: '₹ '),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      const Text('Balance', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('₹${_balance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AccordionSection(
            title: 'Measurements (Optional)',
            icon: Icons.straighten_rounded,
            child: TextField(
              controller: _measureController,
              maxLines: 6,
              minLines: 4,
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                hintText: 'Type measurements freely, e.g.\nChest 34, Waist 28, Shoulder 14\nPant: Waist 30, Length 38\nBoat neck, back open with dori',
              ),
            ),
          ),
          const SizedBox(height: 12),
          AccordionSection(
            title: 'Notes / Photo (Optional)',
            icon: Icons.note_alt_outlined,
            child: Column(
              children: [
                InkWell(
                  onTap: _pickPhoto,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _photoPath == null
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary),
                                SizedBox(height: 6),
                                Text('Tap to capture or upload', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              _photoPreview(_photoPath!),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: 'Notes',
                  child: TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'e.g. Puff sleeves, back open with dori'),
                  ),
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: 'Voice Note',
                  child: VoiceRecorderField(
                    path: _voicePath,
                    onChanged: (p) => setState(() => _voicePath = p),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _canSave ? _save : null,
            child: Text(widget.isEditing ? 'Update Order' : 'Save Order'),
          ),
        ],
      ),
    );
  }
}

/// A read-only field styled like a text input that opens a compact picker
/// sheet on tap — replaces the full-screen dropdown menus.
class _PickerField extends StatelessWidget {
  final IconData icon;
  final String hint;
  final String? value;
  final VoidCallback onTap;

  const _PickerField({required this.icon, required this.hint, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(prefixIcon: Icon(icon)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value! : hint,
                overflow: TextOverflow.ellipsis,
                style: hasValue
                    ? null
                    : TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 18, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.replay_circle_filled_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Repeat Customer', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('Create order quickly with previous measurements', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}
