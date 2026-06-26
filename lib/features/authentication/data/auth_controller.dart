import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper over Supabase email/password auth. Shop creation itself is
/// handled server-side by the `tt_on_auth_user_created` trigger, which reads
/// the shop/owner name we pass here as user metadata.
class AuthController {
  final SupabaseClient _client;
  AuthController(this._client);

  Session? get session => _client.auth.currentSession;
  User? get user => _client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String shopName,
    required String ownerName,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'shop_name': shopName.trim(), 'owner_name': ownerName.trim()},
    );
  }

  /// Sends a password-reset email. [redirectTo] is where the link returns
  /// the user (the deployed app, so they can set a new password).
  Future<void> sendPasswordReset(String email, {String? redirectTo}) async {
    await _client.auth.resetPasswordForEmail(email.trim(), redirectTo: redirectTo);
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(supabaseClientProvider));
});

/// Emits on every sign-in / sign-out / token refresh.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});
