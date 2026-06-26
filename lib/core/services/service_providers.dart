import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';
import 'storage_service.dart';

/// Single place to swap mock implementations for real Firebase-backed ones
/// once `firebase_core`/`firebase_auth`/`firebase_storage` are added to
/// pubspec.yaml and `flutterfire configure` has run.
final authServiceProvider = Provider<AuthService>((ref) => MockAuthService());
final storageServiceProvider = Provider<StorageService>((ref) => MockStorageService());
