import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ShareService {
  static Future<void> shareScreenshot(
    ScreenshotController screenshotController,
    BuildContext context,
  ) async {
    try {
      Uint8List? imageBytes = await screenshotController.capture(
        delay: Duration(milliseconds: 10),
      );

      if (imageBytes == null) {
        throw Exception("Screenshot konnte nicht erstellt werden.");
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'alpenpreisgrenze_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';

      final imageFile = await File(filePath).create();
      await imageFile.writeAsBytes(imageBytes);

      await Share.shareXFiles([XFile(filePath)]);
    } catch (e, s) {
      print("Fehler beim Teilen mit Screenshot: $e\nStack Trace: $s");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen/Teilen des Screenshots: $e'),
          ),
        );
      }
    }
  }
}
