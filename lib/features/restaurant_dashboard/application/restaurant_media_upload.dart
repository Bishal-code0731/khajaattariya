import '../../../core/utils/image_upload.dart';
import '../../../main.dart';

/// Storage paths in the `restaurant-media` bucket (JPG/PNG/WebP, 1 MB).
class RestaurantMediaPaths {
  RestaurantMediaPaths._();

  static String logo(String ownerId) => 'logos/$ownerId/logo.jpg';

  static String menuItem(String restaurantId) =>
      'menu-items/$restaurantId/${DateTime.now().microsecondsSinceEpoch}.jpg';
}

/// Picks, compresses and uploads a photo to `restaurant-media/[path]`.
Future<String?> uploadRestaurantMedia(String path) {
  return ImageUpload.pickCompressAndUpload(
    supabase: supabase,
    bucket: 'restaurant-media',
    path: path,
    maxDimension: 800,
  );
}
