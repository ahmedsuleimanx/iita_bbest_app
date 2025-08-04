import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling image uploads to Firebase Storage
class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload a single image to Firebase Storage
  static Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    String? customFileName,
  }) async {
    try {
      // Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ?? 'image_$timestamp.jpg';
      final fullPath = '$folder/$fileName';

      // Create storage reference
      final ref = _storage.ref().child(fullPath);

      // Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'folder': folder,
        },
      );

      // Upload file
      final uploadTask = ref.putFile(imageFile, metadata);
      
      // Wait for completion
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage Error: ${e.code} - ${e.message}');
      
      // Handle specific Firebase errors
      switch (e.code) {
        case 'storage/object-not-found':
          throw Exception('Storage bucket not found. Please configure Firebase Storage.');
        case 'storage/unauthorized':
          throw Exception('Permission denied. Please check Firebase Storage security rules.');
        case 'storage/canceled':
          throw Exception('Upload was canceled.');
        case 'storage/unknown':
          throw Exception('Unknown error occurred during upload.');
        default:
          throw Exception('Upload failed: ${e.message}');
      }
    } catch (e) {
      print('Image Upload Error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload multiple images to Firebase Storage
  static Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folder,
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        // Report progress
        onProgress?.call(i + 1, imageFiles.length);
        
        // Upload individual image
        final url = await uploadImage(
          imageFile: imageFiles[i],
          folder: folder,
          customFileName: 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        
        if (url != null) {
          uploadedUrls.add(url);
        }
      } catch (e) {
        print('Failed to upload image $i: $e');
        // Continue with other images even if one fails
      }
    }
    
    return uploadedUrls;
  }

  /// Delete an image from Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Failed to delete image: $e');
      return false;
    }
  }

  /// Check if Firebase Storage is properly configured
  static Future<bool> checkStorageConfiguration() async {
    try {
      // Try to create a reference to test storage access
      final testRef = _storage.ref().child('test/config_check.txt');
      
      // This will throw an error if storage is not configured
      await testRef.getMetadata().catchError((e) {
        // If file doesn't exist, that's fine - storage is configured
        if (e.toString().contains('object-not-found')) {
          return FullMetadata({});
        }
        throw e;
      });
      
      return true;
    } catch (e) {
      print('Storage configuration check failed: $e');
      return false;
    }
  }

  /// Get storage usage information
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'error': 'User not authenticated'};

      return {
        'userId': user.uid,
        'storageConfigured': await checkStorageConfiguration(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
