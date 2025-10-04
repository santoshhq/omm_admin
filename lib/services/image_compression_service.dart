import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageCompressionService {
  // Compress image and return as base64 string
  static Future<String?> compressImageToBase64({
    required File imageFile,
    int maxWidth = 1280,
    int maxHeight = 720,
    int quality = 70,
  }) async {
    try {
      print('🖼️ Starting image compression...');
      print('📁 Original file: ${imageFile.path}');

      final originalBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(originalBytes);

      if (image == null) {
        print('❌ Failed to decode image');
        return null;
      }

      print('📏 Original dimensions: ${image.width}x${image.height}');
      print(
        '📦 Original size: ${(originalBytes.length / 1024).toStringAsFixed(1)} KB',
      );

      // Resize image if needed
      img.Image resizedImage = image;
      if (image.width > maxWidth || image.height > maxHeight) {
        double aspectRatio = image.width / image.height;
        int newWidth, newHeight;

        if (aspectRatio > 1) {
          // Landscape
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          // Portrait
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }

        resizedImage = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
        );
        print(
          '📏 Resized dimensions: ${resizedImage.width}x${resizedImage.height}',
        );
      }

      // Compress image
      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: quality),
      );

      print(
        '📦 Compressed size: ${(compressedBytes.length / 1024).toStringAsFixed(1)} KB',
      );
      print(
        '💾 Compression ratio: ${((1 - compressedBytes.length / originalBytes.length) * 100).toStringAsFixed(1)}%',
      );

      // Convert to base64
      final base64String = base64Encode(compressedBytes);
      final extension = imageFile.path.split('.').last.toLowerCase();
      final dataUrl = 'data:image/$extension;base64,$base64String';

      print('✅ Image compression completed');
      return dataUrl;
    } catch (e) {
      print('❌ Error compressing image: $e');
      return null;
    }
  }

  // Compress multiple images
  static Future<List<String>> compressMultipleImages({
    required List<File> imageFiles,
    int maxWidth = 1280,
    int maxHeight = 720,
    int quality = 70,
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> compressedImages = [];

    print('🖼️ Starting multiple image compression...');
    print('📸 Total images: ${imageFiles.length}');

    for (int i = 0; i < imageFiles.length; i++) {
      onProgress?.call(i + 1, imageFiles.length);

      final compressedImage = await compressImageToBase64(
        imageFile: imageFiles[i],
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );

      if (compressedImage != null) {
        compressedImages.add(compressedImage);
      } else {
        print('⚠️ Failed to compress image ${i + 1}/${imageFiles.length}');
      }
    }

    print('✅ Multiple image compression completed');
    print(
      '📊 Successfully compressed: ${compressedImages.length}/${imageFiles.length} images',
    );

    return compressedImages;
  }

  // Get file size in human readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Validate image file
  static bool isValidImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
  }

  // Get optimal quality based on image size
  static int getOptimalQuality(int originalSize) {
    if (originalSize > 5 * 1024 * 1024) {
      // > 5MB
      return 50;
    } else if (originalSize > 2 * 1024 * 1024) {
      // > 2MB
      return 60;
    } else if (originalSize > 1024 * 1024) {
      // > 1MB
      return 70;
    } else {
      return 80;
    }
  }
}
