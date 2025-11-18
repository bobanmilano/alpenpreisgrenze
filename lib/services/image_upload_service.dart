import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:my_price_tracker_app/services/image_processing_service.dart';

class ImageUploadService {
  static Future<List<String>> uploadImages(List<File> images) async {
    List<String> downloadUrls = [];

    for (int i = 0; i < images.length; i++) {
      final image = images[i];

      try {
        _showProgressMessage(
          'Optimiere Bild ${i + 1} von ${images.length}...',
          Duration(seconds: 2),
        );

        final optimizedImage = await ImageProcessingService.optimizeForMobile(
          image,
        );

        _showProgressMessage(
          'Lade Bild ${i + 1} von ${images.length} hoch...',
          Duration(seconds: 3),
        );

        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${i + 1}.jpg';
        final Reference storageRef = FirebaseStorage.instance.ref().child(
          'apartment_images/$fileName',
        );

        UploadTask uploadTask = storageRef.putFile(optimizedImage);

        TaskSnapshot snapshot = await uploadTask.timeout(Duration(seconds: 30));
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);

        if (optimizedImage.path != image.path) {
          await optimizedImage.delete();
        }
      } catch (e) {
        print('Fehler beim Upload von Bild ${i + 1}: $e');
        throw Exception('Fehler beim Upload von Bild ${i + 1}: $e');
      }
    }

    return downloadUrls;
  }

  static void _showProgressMessage(String message, Duration duration) {
    print('Upload Progress: $message');
  }

  static Future<List<String>> uploadImagesWithProgress(
    List<File> images,
    Function(String message) onProgress,
  ) async {
    List<String> downloadUrls = [];

    for (int i = 0; i < images.length; i++) {
      final image = images[i];

      try {
        onProgress('Optimiere Bild ${i + 1} von ${images.length}...');
        final optimizedImage = await ImageProcessingService.optimizeForMobile(
          image,
        );

        onProgress('Lade Bild ${i + 1} von ${images.length} hoch...');

        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${i + 1}.jpg';
        final Reference storageRef = FirebaseStorage.instance.ref().child(
          'apartment_images/$fileName',
        );

        UploadTask uploadTask = storageRef.putFile(optimizedImage);

        TaskSnapshot snapshot = await uploadTask.timeout(Duration(seconds: 30));
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);

        if (optimizedImage.path != image.path) {
          await optimizedImage.delete();
        }
      } catch (e) {
        print('Fehler beim Upload von Bild ${i + 1}: $e');
        throw Exception('Fehler beim Upload von Bild ${i + 1}: $e');
      }
    }

    return downloadUrls;
  }

  static Future<File> optimizeForMobile(File imageFile) async {
    try {
      if (isImageSizeValid(imageFile)) {
        return imageFile;
      }

      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Konnte Bild nicht decodieren');
      }

      int maxWidth = 1024;
      int quality = 80;

      while (maxWidth >= 400 && quality >= 30) {
        final resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.width <= image.height ? maxWidth : null,
        );

        final resizedBytes = img.encodeJpg(resizedImage, quality: quality);

        final tempDir = Directory.systemTemp;
        final tempFile = File(
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(resizedBytes);

        if (isImageSizeValid(tempFile)) {
          print(
            'Bild optimiert: ${getImageSizeInKB(imageFile).toStringAsFixed(1)}KB → ${getImageSizeInKB(tempFile).toStringAsFixed(1)}KB',
          );
          return tempFile;
        }

        await tempFile.delete();

        if (quality > 40) {
          quality -= 10;
        } else {
          maxWidth -= 100;
          quality = 80;
        }
      }

      final finalResized = img.copyResize(image, width: 400, height: 400);
      final finalBytes = img.encodeJpg(finalResized, quality: 30);
      final finalTempFile = File(
        '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}_final.jpg',
      );
      await finalTempFile.writeAsBytes(finalBytes);

      return finalTempFile;
    } catch (e) {
      print('Fehler bei der Bildoptimierung: $e');
      return imageFile;
    }
  }

  static bool isImageSizeValid(File imageFile) {
    final sizeInBytes = imageFile.lengthSync();
    final sizeInKB = sizeInBytes / 1024;
    return sizeInKB <= 200;
  }

  static double getImageSizeInKB(File imageFile) {
    final sizeInBytes = imageFile.lengthSync();
    return sizeInBytes / 1024;
  }
}
