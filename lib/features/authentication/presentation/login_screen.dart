import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widgets/labeled_field.dart';
import '../data/auth_controller.dart';
import 'auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider).signIn(email: _email.text, password: _password.text);
      // The router's auth gate redirects to /home automatically.
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to manage your tailoring business.',
      children: [
        LabeledField(
          label: 'Email',
          child: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded), hintText: 'you@example.com'),
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Password',
          child: TextField(
            controller: _password,
            obscureText: _obscure,
            onSubmitted: (_) => _login(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/forgot-password'),
            child: const Text('Forgot password?'),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
        ],
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _busy ? null : _login,
          child: _busy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Sign In'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("New here?"),
            TextButton(onPressed: () => context.push('/signup'), child: const Text('Create an account')),
          ],
        ),
      ],
    );
  }
}
