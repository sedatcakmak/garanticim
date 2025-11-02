import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Show action sheet to choose between camera and gallery
  Future<File?> pickImage() async {
    // This method will be called from UI with context to show action sheet
    // For now, just return gallery as default
    return await pickImageFromGallery();
  }

  Future<String?> uploadImage(
    File image,
    String userId,
    String imageType,
  ) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$imageType.jpg';
      final ref = _storage.ref().child('users/$userId/$fileName');

      final uploadTask = ref.putFile(
        image,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<String?> uploadProductImage(File image, String userId) async {
    return await uploadImage(image, userId, 'product');
  }

  Future<String?> uploadInvoiceImage(File image, String userId) async {
    return await uploadImage(image, userId, 'invoice');
  }
}
