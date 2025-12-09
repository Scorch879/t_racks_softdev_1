import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class ImageService {
  final _picker = ImagePicker();

  /// Picks an image from the gallery, uploads it to Supabase Storage,
  /// and returns the public URL.
  ///
  /// Throws an exception if the user cancels or an error occurs.
  Future<String> pickAndUploadImage() async {
    try {
      // 1. Pick an image from the gallery
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image to save space
      );

      if (pickedFile == null) {
        throw 'No image selected.';
      }

      final imageFile = File(pickedFile.path);
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not logged in.';
      }

      // 2. Create a unique file path
      final fileExtension = pickedFile.path.split('.').last;
      final filePath = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      // 3. Upload to the 'user-image' bucket
      await _supabase.storage.from('user-images').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true, // Overwrite if a file with the same name exists
            ),
          );

      // 4. Get the public URL of the uploaded file
      final imageUrl = _supabase.storage
          .from('user-images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      print('Error in pickAndUploadImage: $e');
      rethrow; // Rethrow to be handled by the UI
    }
  }
}