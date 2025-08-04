import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Upload types for organizing images
enum UploadType {
  product('product'),
  user('user'),
  admin('admin');
  
  const UploadType(this.folderName);
  final String folderName;
}

/// Service for handling local image uploads and storage
class LocalImageService {
  static const String _uploadsFolderName = 'uploads';
  
  /// Get the base upload directory path
  static Future<String> _getBaseUploadPath() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return path.join(appDocDir.path, _uploadsFolderName);
  }

  /// Upload a single image to local storage
  static Future<String?> uploadImage({
    required File imageFile,
    required UploadType uploadType,
    String? customFileName,
  }) async {
    try {
      // Generate unique filename if not provided
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = customFileName ?? 'image_$timestamp$extension';
      
      // Get the base upload path
      final baseUploadPath = await _getBaseUploadPath();
      
      // Create the full path
      final uploadDir = path.join(baseUploadPath, uploadType.folderName);
      final fullPath = path.join(uploadDir, fileName);
      
      // Ensure the directory exists
      final directory = Directory(uploadDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Copy the file to the uploads directory
      final destinationFile = File(fullPath);
      await imageFile.copy(destinationFile.path);
      
      // Return the full path that can be used in the app
      return fullPath;
    } catch (e) {
      print('Error uploading image locally: $e');
      return null;
    }
  }

  /// Upload multiple images to local storage
  static Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required UploadType uploadType,
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> uploadedPaths = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        // Report progress
        onProgress?.call(i + 1, imageFiles.length);
        
        // Upload individual image
        final imagePath = await uploadImage(
          imageFile: imageFiles[i],
          uploadType: uploadType,
          customFileName: 'image_${DateTime.now().millisecondsSinceEpoch}_$i${path.extension(imageFiles[i].path)}',
        );
        
        if (imagePath != null) {
          uploadedPaths.add(imagePath);
        }
      } catch (e) {
        print('Failed to upload image $i: $e');
        // Continue with other images even if one fails
      }
    }
    
    return uploadedPaths;
  }

  /// Delete an image from local storage
  static Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to delete image: $e');
      return false;
    }
  }

  /// Get all images from a specific upload type folder
  static Future<List<String>> getImagesFromFolder(UploadType uploadType) async {
    try {
      final baseUploadPath = await _getBaseUploadPath();
      final uploadDir = Directory(path.join(baseUploadPath, uploadType.folderName));
      
      if (!await uploadDir.exists()) {
        return [];
      }
      
      final files = await uploadDir.list().toList();
      final imagePaths = <String>[];
      
      for (final file in files) {
        if (file is File && _isImageFile(file.path)) {
          imagePaths.add(file.path);
        }
      }
      
      return imagePaths;
    } catch (e) {
      print('Error getting images from folder: $e');
      return [];
    }
  }

  /// Check if a file is an image based on its extension
  static bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }

  /// Get the size of an image file
  static Future<int> getImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Error getting image size: $e');
      return 0;
    }
  }

  /// Clean up old images (older than specified days)
  static Future<int> cleanupOldImages({
    required UploadType uploadType,
    int olderThanDays = 30,
  }) async {
    try {
      final baseUploadPath = await _getBaseUploadPath();
      final uploadDir = Directory(path.join(baseUploadPath, uploadType.folderName));
      
      if (!await uploadDir.exists()) {
        return 0;
      }
      
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      final files = await uploadDir.list().toList();
      int deletedCount = 0;
      
      for (final file in files) {
        if (file is File && _isImageFile(file.path)) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            deletedCount++;
          }
        }
      }
      
      return deletedCount;
    } catch (e) {
      print('Error cleaning up old images: $e');
      return 0;
    }
  }

  /// Get storage info for all upload folders
  static Future<Map<String, dynamic>> getStorageInfo() async {
    final info = <String, dynamic>{};
    
    for (final uploadType in UploadType.values) {
      try {
        final images = await getImagesFromFolder(uploadType);
        int totalSize = 0;
        
        for (final imagePath in images) {
          totalSize += await getImageSize(imagePath);
        }
        
        info[uploadType.folderName] = {
          'count': images.length,
          'totalSize': totalSize,
          'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        };
      } catch (e) {
        info[uploadType.folderName] = {
          'error': e.toString(),
        };
      }
    }
    
    return info;
  }

  /// Copy image from assets to uploads folder (for default images)
  static Future<String?> copyAssetToUploads({
    required String assetPath,
    required UploadType uploadType,
    required String fileName,
  }) async {
    try {
      // Load the asset
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      
      // Get the base upload path
      final baseUploadPath = await _getBaseUploadPath();
      
      // Create the destination path
      final uploadDir = path.join(baseUploadPath, uploadType.folderName);
      final fullPath = path.join(uploadDir, fileName);
      
      // Ensure the directory exists
      final directory = Directory(uploadDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Write the file
      final file = File(fullPath);
      await file.writeAsBytes(bytes);
      
      return fullPath;
    } catch (e) {
      print('Error copying asset to uploads: $e');
      return null;
    }
  }

  /// Check if local storage is available and writable
  static Future<bool> checkStorageAvailability() async {
    try {
      // Get the base upload path
      final baseUploadPath = await _getBaseUploadPath();
      
      // Try to create a test file
      final testDir = Directory(baseUploadPath);
      if (!await testDir.exists()) {
        await testDir.create(recursive: true);
      }
      
      final testFile = File(path.join(baseUploadPath, 'test.txt'));
      await testFile.writeAsString('test');
      
      final exists = await testFile.exists();
      if (exists) {
        await testFile.delete();
      }
      
      return exists;
    } catch (e) {
      print('Storage availability check failed: $e');
      return false;
    }
  }
}
