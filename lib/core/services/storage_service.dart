import 'dart:io';

/// Abstraction over file uploads (order photos). [MockStorageService] keeps
/// files on local disk only; swap for a `FirebaseStorageService` later by
/// providing it in the same provider slot.
abstract class StorageService {
  Future<String> uploadOrderPhoto({required String orderId, required File file});
}

class MockStorageService implements StorageService {
  @override
  Future<String> uploadOrderPhoto({required String orderId, required File file}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return file.path;
  }
}
