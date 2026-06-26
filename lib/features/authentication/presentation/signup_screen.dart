import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widgets/labeled_field.dart';
import '../data/auth_controller.dart';
import 'auth_scaffold.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _shopName = TextEditingController();
  final _ownerName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _shopName.dispose();
    _ownerName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _valid =>
      _shopName.text.trim().isNotEmpty &&
      _ownerName.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _password.text.length >= 6;

  Future<void> _signup() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authControllerProvider).signUp(
            email: _email.text,
            password: _password.text,
            shopName: _shopName.text,
            ownerName: _ownerName.text,
          );
      // If email confirmation is on, there's no session yet — tell the user.
      final signedIn = ref.read(authControllerProvider).session != null;
      if (!signedIn && mounted) {
        setState(() => _info = 'Account created! Check your email to confirm, then sign in.');
      }
      // If confirmation is off, the auth gate redirects to /home automatically.
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your shop',
      subtitle: 'Set up TailorTrack for your tailoring business.',
      children: [
        LabeledField(
          label: 'Shop Name',
          child: TextField(
            controller: _shopName,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.storefront_outlined), hintText: 'e.g. Lakshmi Tailors'),
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Owner Name',
          child: TextField(
            controller: _ownerName,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded), hintText: 'Your name'),
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Email',
          child: TextField(
            controller: _email,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded), hintText: 'you@example.com'),
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Password',
          child: TextField(
            controller: _password,
            obscureText: _obscure,
            onChanged: (_) => setState(() {}),
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
        if (_info != null) ...[
          const SizedBox(height: 12),
          Text(_info!, style: const TextStyle(color: Color(0xFF0F8A5F), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: (_busy || !_valid) ? null : _signup,
          child: _busy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create Account'),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account?'),
            TextButton(onPressed: () => context.pop(), child: const Text('Sign in')),
          ],
        ),
      ],
    );
  }
}
