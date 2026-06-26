import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// Compact bottom-sheet picker used instead of full-screen dropdown menus.
/// Rows are tight and the sheet is height-capped, so picking a dress type or
/// delivery time never takes over the whole screen.
///
/// If [addNewLabel] is provided, a final "add new" row lets the user type a
/// new value; the typed string is returned just like any other option, and
/// the caller decides whether to persist it.
Future<String?> showOptionPicker(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
  String? addNewLabel,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    showDragHandle: true,
    constraints: const BoxConstraints(maxHeight: 460),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                children: [
                  for (final o in options)
                    ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Text(o, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: o == selected ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () => Navigator.of(context).pop(o),
                    ),
                  if (addNewLabel != null)
                    ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                      title: Text(addNewLabel, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () async {
                        final created = await _promptNewValue(context, addNewLabel);
                        if (created != null && created.trim().isNotEmpty && context.mounted) {
                          Navigator.of(context).pop(created.trim());
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<String?> _promptNewValue(BuildContext context, String label) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      title: Text(label),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'e.g. Frock'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
