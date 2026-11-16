import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_logger.dart';

/// Shared pick → compress → upload flow for any Supabase Storage bucket.
class ImageUpload {
  ImageUpload._();

  static Future<String?> pickCompressAndUpload({
    required SupabaseClient supabase,
    required String bucket,
    required String path,
    int maxDimension = 800,
    int quality = 80,
  }) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
      imageQuality: quality,
    );
    if (picked == null) return null;

    final original = await picked.readAsBytes();
    var bytes = original;
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        original,
        minWidth: maxDimension,
        minHeight: maxDimension,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (compressed.isNotEmpty && compressed.length < original.length) {
        bytes = compressed;
      }
    } catch (e) {
      AppLogger.warning('image_upload', 'compression skipped: $e');
    }

    await supabase.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions:
              const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return supabase.storage.from(bucket).getPublicUrl(path);
  }
}
