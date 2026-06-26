import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widgets/labeled_field.dart';
import '../data/auth_controller.dart';
import 'auth_scaffold.dart';

/// Reached from the password-reset email link. Supabase has, by then, created
/// a temporary recovery session, so `updateUser(password)` is allowed.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_password.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider).updatePassword(_password.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. You are signed in.')));
        context.go('/home');
      }
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Set a new password',
      subtitle: 'Choose a new password for your account.',
      children: [
        LabeledField(
          label: 'New Password',
          child: TextField(
            controller: _password,
            obscureText: _obscure,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              hintText: 'At least 6 characters',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Update Password'),
        ),
      ],
    );
  }
}
