// lib/services/image_processing_service.dart
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';

class ImageProcessingService {
  /// Optimiert Bilder automatisch auf max. 50KB mit Fortschrittsanzeige
  static Future<File> optimizeForMobile(File imageFile) async {
    try {
      print('Starte Optimierung für: ${imageFile.path}');
      
      // Prüfe zuerst ob Bild bereits klein genug ist
      if (isImageSizeValid(imageFile)) {
        print('Bild bereits klein genug: ${getImageSizeInKB(imageFile).toStringAsFixed(1)}KB');
        return imageFile; // Keine Optimierung nötig
      }

      // Lese das Originalbild
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Konnte Bild nicht decodieren');
      }

      print('Originalgröße: ${getImageSizeInKB(imageFile).toStringAsFixed(1)}KB');
      print('Starte Optimierung...');

      // Schrittweise Optimierung bis Zielgröße erreicht
      int maxWidth = 800; // Reduziert
      int quality = 70; // Reduziert
      int attempt = 1;
      
      while (maxWidth >= 200 && quality >= 20) { // Noch strengere Grenzen
        print('Optimierungsversuch $attempt: Breite=$maxWidth, Qualität=$quality');
        
        // Verkleinere das Bild
        final resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.width <= image.height ? maxWidth : null,
        );

        // Konvertiere zu JPEG
        final resizedBytes = img.encodeJpg(resizedImage, quality: quality);
        
        // Speichere temporär und prüfe Größe
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_attempt_$attempt.jpg');
        await tempFile.writeAsBytes(resizedBytes);
        
        final newSize = getImageSizeInKB(tempFile);
        print('Ergebnis: ${newSize.toStringAsFixed(1)}KB');
        
        // Prüfe ob Größe okay ist
        if (isImageSizeValid(tempFile)) {
          print('Optimierung erfolgreich! ${getImageSizeInKB(imageFile).toStringAsFixed(1)}KB → ${newSize.toStringAsFixed(1)}KB');
          return tempFile;
        }
        
        // Aufräumen
        await tempFile.delete();
        
        // Reduziere Qualität oder Größe
        if (quality > 30) {
          quality -= 10;
        } else {
          maxWidth -= 100;
          quality = 70; // Reset Qualität
        }
        
        attempt++;
      }
      
      // Letzter Versuch mit minimalen Einstellungen
      print('Letzter Optimierungsversuch mit minimalen Einstellungen...');
      final finalResized = img.copyResize(image, width: 200, height: 200);
      final finalBytes = img.encodeJpg(finalResized, quality: 20);
      final finalTempFile = File('${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}_final.jpg');
      await finalTempFile.writeAsBytes(finalBytes);
      
      final finalSize = getImageSizeInKB(finalTempFile);
      print('Finale Optimierung: ${getImageSizeInKB(imageFile).toStringAsFixed(1)}KB → ${finalSize.toStringAsFixed(1)}KB');
      
      return finalTempFile;
      
    } catch (e) {
      print('Fehler bei der Bildoptimierung: $e');
      return imageFile; // Return original if optimization fails
    }
  }

  /// Validiert die Bildgröße (max. 50KB)
  static bool isImageSizeValid(File imageFile) {
    final sizeInBytes = imageFile.lengthSync();
    final sizeInKB = sizeInBytes / 1024;
    return sizeInKB <= 50; // Max. 50KB
  }

  /// Berechne Bildgröße in KB
  static double getImageSizeInKB(File imageFile) {
    final sizeInBytes = imageFile.lengthSync();
    return sizeInBytes / 1024;
  }
}