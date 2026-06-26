import 'package:flutter/material.dart';

/// Wraps a [TextFormField]-like child with the small uppercase-ish label
/// style used throughout the New Order form (e.g. "Customer Name *").
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)),
          ),
        ),
        child,
      ],
    );
  }
}
