import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/authentication/data/auth_controller.dart';

/// Handles compressing and uploading order media (photos + voice notes) to
/// the shop's private storage folder, and resolving signed URLs for display.
///
/// Object paths follow `{shop_id}/{filename}` inside the `photos` and
/// `voice-notes` buckets, which the storage RLS policies enforce.
class MediaService {
  final SupabaseClient _client;
  MediaService(this._client);

  static const photosBucket = 'photos';
  static const voiceBucket = 'voice-notes';

  /// True when [path] is already a storage object path (`shop/file`), not a
  /// freshly-picked local file / blob URL that still needs uploading.
  bool _isRemote(String path) {
    return !path.startsWith('/') && !path.startsWith('blob:') && !path.startsWith('http') && !path.startsWith('file:');
  }

  /// Compresses an image to ~1280px longest side / JPEG q70 (target
  /// 150–300 KB). Falls back to the original bytes if compression is
  /// unavailable on the platform (e.g. some web setups).
  Future<Uint8List> _compressImage(String path) async {
    try {
      if (!kIsWeb) {
        final out = await FlutterImageCompress.compressWithFile(
          path,
          minWidth: 1280,
          minHeight: 1280,
          quality: 70,
          format: CompressFormat.jpeg,
        );
          if (out != null) return out;
      }
    } catch (_) {/* fall through to raw bytes */}
    return XFile(path).readAsBytes();
  }

  /// Uploads a photo if it's a new local file; returns the storage object path
  /// (or the existing remote path unchanged).
  Future<String?> ensurePhotoUploaded(String? path, String shopId) async {
    if (path == null || path.isEmpty) return null;
    if (_isRemote(path)) return path;
    final bytes = await _compressImage(path);
    final objectPath = '$shopId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from(photosBucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return objectPath;
  }

  /// Uploads a voice note (already AAC/.m4a from the recorder) if it's new.
  Future<String?> ensureVoiceUploaded(String? path, String shopId) async {
    if (path == null || path.isEmpty) return null;
    if (_isRemote(path)) return path;
    final bytes = await XFile(path).readAsBytes();
    final objectPath = '$shopId/${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _client.storage.from(voiceBucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(contentType: 'audio/mp4', upsert: true),
        );
    return objectPath;
  }

  /// A short-lived signed URL for a stored object so it can be shown/played.
  Future<String> signedUrl(String bucket, String objectPath) {
    return _client.storage.from(bucket).createSignedUrl(objectPath, 60 * 60);
  }
}

final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService(ref.watch(supabaseClientProvider));
});

/// Resolves a signed URL for a stored object path so order media can be shown.
final signedUrlProvider = FutureProvider.family<String, ({String bucket, String path})>((ref, args) {
  return ref.watch(mediaServiceProvider).signedUrl(args.bucket, args.path);
});
