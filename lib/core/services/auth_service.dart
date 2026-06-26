/// Abstraction over phone-OTP authentication. [MockAuthService] is used
/// until Firebase is wired up — swap the provider override in main.dart for
/// a `FirebaseAuthService` implementation without touching call sites.
abstract class AuthService {
  Future<String> sendOtp(String phoneNumber);
  Future<bool> verifyOtp({required String verificationId, required String otp});
  Future<void> signOut();
  bool get isSignedIn;
}

class MockAuthService implements AuthService {
  bool _signedIn = false;

  @override
  bool get isSignedIn => _signedIn;

  @override
  Future<String> sendOtp(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return 'mock-verification-id';
  }

  @override
  Future<bool> verifyOtp({required String verificationId, required String otp}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _signedIn = true;
    return true;
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
  }
}
