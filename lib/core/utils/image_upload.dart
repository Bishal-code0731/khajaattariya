import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared pick → compress → upload flow for any Supabase Storage bucket.
/// Centralizes the compression step so every upload path (avatar,
/// restaurant logo, menu-item photo) re-encodes to a bounded size
/// before it ever leaves the device — important for staying inside the
/// Supabase free tier's 1GB storage budget.
class ImageUpload {
  ImageUpload._();

  /// Picks an image from the gallery, compresses it to at most
  /// [maxDimension] on its longest side at [quality]%, uploads it to
  /// [bucket]/[path] (overwriting any existing file at that path), and
  /// returns the public URL. Returns null if the user cancelled the
  /// picker.
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
    );
    if (picked == null) return null;

    final compressedBytes = await FlutterImageCompress.compressWithFile(
      picked.path,
      minWidth: maxDimension,
      minHeight: maxDimension,
      quality: quality,
      format: CompressFormat.jpeg,
    );

    // compressWithFile can return null for formats it can't re-encode
    // (rare) — fall back to the already-downscaled original rather than
    // silently failing the whole upload.
    final bytes = compressedBytes ?? await File(picked.path).readAsBytes();

    // Supabase's upload() needs a real file on most platforms — write
    // the compressed bytes to a temp file rather than the picker's
    // original (uncompressed) one.
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/upload_${DateTime.now().microsecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(bytes);

    try {
      await supabase.storage.from(bucket).upload(
        path,
        tempFile,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
      return supabase.storage.from(bucket).getPublicUrl(path);
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
    }
  }
}
