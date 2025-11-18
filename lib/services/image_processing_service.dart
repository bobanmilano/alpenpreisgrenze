import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';

class ImageProcessingService {
  static Future<File> optimizeForMobile(File imageFile) async {
    try {
      print('Starte Optimierung für: ${imageFile.path}');

      if (isImageSizeValid(imageFile)) {
        print(
          'Bild bereits klein genug: ${getImageSizeInKB(imageFile).toStringAsFixed(1)}KB',
        );
        return imageFile;
      }

      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Konnte Bild nicht decodieren');
      }

      print(
        'Originalgröße: ${getImageSizeInKB(imageFile).toStringAsFixed(1)}KB',
      );
      print('Starte Optimierung...');

      int maxWidth = 800;
      int quality = 70;
      int attempt = 1;

      while (maxWidth >= 200 && quality >= 20) {
        print(
          'Optimierungsversuch $attempt: Breite=$maxWidth, Qualität=$quality',
        );

        final resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.width <= image.height ? maxWidth : null,
        );

        final resizedBytes = img.encodeJpg(resizedImage, quality: quality);

        final tempDir = Directory.systemTemp;
        final tempFile = File(
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_attempt_$attempt.jpg',
        );
        await tempFile.writeAsBytes(resizedBytes);

        final newSize = getImageSizeInKB(tempFile);
        print('Ergebnis: ${newSize.toStringAsFixed(1)}KB');

        if (isImageSizeValid(tempFile)) {
          print(
            'Optimierung erfolgreich! ${getImageSizeInKB(imageFile).toStringAsFixed(1)}KB → ${newSize.toStringAsFixed(1)}KB',
          );
          return tempFile;
        }

        await tempFile.delete();

        if (quality > 30) {
          quality -= 10;
        } else {
          maxWidth -= 100;
          quality = 70;
        }

        attempt++;
      }

      print('Letzter Optimierungsversuch mit minimalen Einstellungen...');
      final finalResized = img.copyResize(image, width: 200, height: 200);
      final finalBytes = img.encodeJpg(finalResized, quality: 20);
      final finalTempFile = File(
        '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}_final.jpg',
      );
      await finalTempFile.writeAsBytes(finalBytes);

      final finalSize = getImageSizeInKB(finalTempFile);
      print(
        'Finale Optimierung: ${getImageSizeInKB(imageFile).toStringAsFixed(1)}KB → ${finalSize.toStringAsFixed(1)}KB',
      );

      return finalTempFile;
    } catch (e) {
      print('Fehler bei der Bildoptimierung: $e');
      return imageFile;
    }
  }

  static bool isImageSizeValid(File imageFile) {
    final sizeInBytes = imageFile.lengthSync();
    final sizeInKB = sizeInBytes / 1024;
    return sizeInKB <= 50;
  }

  static double getImageSizeInKB(File imageFile) {
    final sizeInBytes = imageFile.lengthSync();
    return sizeInBytes / 1024;
  }
}
