// lib/services/image_upload_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:my_price_tracker_app/services/image_processing_service.dart';

class ImageUploadService {
  /// Upload mehrerer Bilder mit Fortschrittsanzeige
  static Future<List<String>> uploadImages(List<File> images) async {
    List<String> downloadUrls = [];
    
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      
      try {
        // Zeige Fortschrittsmeldung
        _showProgressMessage(
          'Optimiere Bild ${i + 1} von ${images.length}...',
          Duration(seconds: 2),
        );

        // Optimiere Bild für Smartphone-Nutzung
        final optimizedImage = await ImageProcessingService.optimizeForMobile(image);
        
        // Zeige Upload-Fortschritt
        _showProgressMessage(
          'Lade Bild ${i + 1} von ${images.length} hoch...',
          Duration(seconds: 3),
        );

        // Upload zum Firebase Storage
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${i + 1}.jpg';
        final Reference storageRef =
            FirebaseStorage.instance.ref().child('apartment_images/$fileName');
        
        UploadTask uploadTask = storageRef.putFile(optimizedImage);
        
        TaskSnapshot snapshot = await uploadTask.timeout(Duration(seconds: 30));
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
        
        // Lösche temporäre Datei falls erstellt
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

  /// Zeige Fortschrittsmeldung mit SnackBar
  static void _showProgressMessage(String message, Duration duration) {
    // Diese Methode wird von außen aufgerufen - wir brauchen einen Context
    print('Upload Progress: $message');
  }

  /// Public Methode für Fortschrittsanzeige (wird vom Screen aufgerufen)
  static Future<List<String>> uploadImagesWithProgress(
    List<File> images,
    Function(String message) onProgress,
  ) async {
    List<String> downloadUrls = [];
    
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      
      try {
        // Zeige Optimierungs-Fortschritt
        onProgress('Optimiere Bild ${i + 1} von ${images.length}...');
        final optimizedImage = await ImageProcessingService.optimizeForMobile(image);
        
        // Zeige Upload-Fortschritt
        onProgress('Lade Bild ${i + 1} von ${images.length} hoch...');
        
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${i + 1}.jpg';
        final Reference storageRef =
            FirebaseStorage.instance.ref().child('apartment_images/$fileName');
        
        UploadTask uploadTask = storageRef.putFile(optimizedImage);
        
        TaskSnapshot snapshot = await uploadTask.timeout(Duration(seconds: 30));
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
        
        // Lösche temporäre Datei falls erstellt
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

  /// Optimiert Bilder automatisch auf max. 200KB für Smartphone-Nutzung
  static Future<File> optimizeForMobile(File imageFile) async {
    try {
      // Prüfe zuerst ob Bild bereits klein genug ist
      if (isImageSizeValid(imageFile)) {
        return imageFile; // Keine Optimierung nötig
      }

      // Lese das Originalbild
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Konnte Bild nicht decodieren');
      }

      // Schrittweise Optimierung bis Zielgröße erreicht
      int maxWidth = 1024;
      int quality = 80;
      
      while (maxWidth >= 400 && quality >= 30) {
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
        final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(resizedBytes);
        
        // Prüfe ob Größe okay ist
        if (isImageSizeValid(tempFile)) {
          print('Bild optimiert: ${getImageSizeInKB(imageFile).toStringAsFixed(1)}KB → ${getImageSizeInKB(tempFile).toStringAsFixed(1)}KB');
          return tempFile;
        }
        
        // Aufräumen
        await tempFile.delete();
        
        // Reduziere Qualität oder Größe
        if (quality > 40) {
          quality -= 10;
        } else {
          maxWidth -= 100;
          quality = 80; // Reset Qualität
        }
      }
      
      // Letzter Versuch mit minimalen Einstellungen
      final finalResized = img.copyResize(image, width: 400, height: 400);
      final finalBytes = img.encodeJpg(finalResized, quality: 30);
      final finalTempFile = File('${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}_final.jpg');
      await finalTempFile.writeAsBytes(finalBytes);
      
      return finalTempFile;
      
    } catch (e) {
      print('Fehler bei der Bildoptimierung: $e');
      return imageFile; // Return original if optimization fails
    }
  }

  /// Validiert die Bildgröße (max. 200KB)
  static bool isImageSizeValid(File imageFile) {
    final sizeInBytes = imageFile.lengthSync();
    final sizeInKB = sizeInBytes / 1024;
    return sizeInKB <= 200; // Max. 200KB
  }


  /// Berechne Bildgröße in KB
  static double getImageSizeInKB(File imageFile) {
    final sizeInBytes = imageFile.lengthSync();
    return sizeInBytes / 1024;
  }

}