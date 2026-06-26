import 'package:flutter/material.dart';

import '../../../common/widgets/brand.dart';

/// Shared shell for the auth screens — centered brand lockup, title/subtitle,
/// and a scrollable form column. Matches the app's premium light styling.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showLogo;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showLogo) ...[
                  const Center(child: BrandLogo(size: 56)),
                  const SizedBox(height: 16),
                  const Center(child: BrandWordmark(fontSize: 28)),
                  const SizedBox(height: 28),
                ],
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.65))),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Maps Supabase/auth errors to a short, friendly message.
String friendlyAuthError(Object e) {
  final s = e.toString().toLowerCase();
  if (s.contains('invalid login')) return 'Incorrect email or password.';
  if (s.contains('already registered') || s.contains('already been registered')) return 'That email is already registered.';
  if (s.contains('password should be at least')) return 'Password must be at least 6 characters.';
  if (s.contains('unable to validate email') || s.contains('invalid email')) return 'Please enter a valid email address.';
  if (s.contains('email not confirmed')) return 'Please confirm your email, then sign in.';
  if (s.contains('network') || s.contains('socket') || s.contains('failed host')) return 'No internet connection.';
  return 'Something went wrong. Please try again.';
}
