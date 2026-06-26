import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widgets/labeled_field.dart';
import '../data/auth_controller.dart';
import 'auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // On web, return the user to the deployed app so they can set a new
      // password; on mobile, Supabase handles the recovery deep link.
      final redirect = kIsWeb ? '${Uri.base.origin}/#/reset-password' : null;
      await ref.read(authControllerProvider).sendPasswordReset(_email.text, redirectTo: redirect);
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Reset password',
      subtitle: 'We’ll email you a link to set a new password.',
      children: [
        if (_sent) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFE6F4EE), borderRadius: BorderRadius.circular(16)),
            child: const Text(
              'If an account exists for that email, a reset link is on its way. Check your inbox.',
              style: TextStyle(color: Color(0xFF0B6B49), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: () => context.pop(), child: const Text('Back to sign in')),
        ] else ...[
          LabeledField(
            label: 'Email',
            child: TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded), hintText: 'you@example.com'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy ? null : _send,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send Reset Link'),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.pop(), child: const Text('Back to sign in')),
        ],
      ],
    );
  }
}
