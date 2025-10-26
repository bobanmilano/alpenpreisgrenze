// lib/screens/barcode_scanner_page.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  // Initialisiere den Controller explizit mit Optionen
  late MobileScannerController cameraController = MobileScannerController(
    torchEnabled: false, // Explizit auf false setzen
    // Optional: Andere Einstellungen, falls gewünscht
    // detectionSpeed: DetectionSpeed.normal,
    // cameraFacing: CameraFacing.back, // Standard ist bereits 'back'
  );

  // Zustand, um mehrfaches Scannen nach erstem Fund zu verhindern
  bool isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode scannen'),
        // Optional: Füge Schaltflächen für Torch und Kamerawechsel hinzu, wenn gewünscht
        // actions: [
        //   IconButton(
        //     onPressed: () async {
        //       await cameraController.toggleTorch();
        //       // Optional: setState aufrufen, um das Icon visuell zu aktualisieren
        //       // Dies erfordert jedoch, dass der Torch-Status im Widget-State gespeichert wird.
        //     },
        //     icon: Icon(Icons.flash_off), // Oder Icons.flash_on, je nach Status
        //   ),
        //   IconButton(
        //     onPressed: () async {
        //       await cameraController.switchCamera();
        //       // Optional: setState aufrufen, um das Icon visuell zu aktualisieren
        //     },
        //     icon: Icon(Icons.cameraswitch), // Oder entsprechendes Icon
        //   ),
        // ],
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          // Verhindere weitere Aktionen, wenn Scanning abgeschlossen ist
          if (!isScanning) return;

          final List<Barcode> barcodes = capture.barcodes;
          // Iteriere über alle gefundenen Barcodes (robuster)
          for (final barcode in barcodes) {
            final String? rawValue = barcode.rawValue;
            if (rawValue != null && rawValue.isNotEmpty) {
              // Setze isScanning auf false, um weitere Scans zu stoppen
              setState(() {
                isScanning = false;
              });

              debugPrint('Barcode erkannt: $rawValue');
              // Gibt den Barcode zurück und schließt den Scanner
              if (context.mounted) { // Verwendung von context.mounted
                 Navigator.of(context).pop(rawValue);
              }
              break; // Beende die Schleife nach dem ersten Fund
            }
          }
        },
      ),
      // Optional: Füge einen Hinweis am unteren Rand hinzu
      // bottomNavigationBar: Container(
      //   height: 80,
      //   color: Colors.black.withOpacity(0.8),
      //   child: Center(
      //     child: Text(
      //       'Scanne einen Barcode',
      //       style: TextStyle(
      //         color: Colors.white,
      //         fontSize: 16,
      //         fontWeight: FontWeight.bold,
      //       ),
      //     ),
      //   ),
      // ),
    );
  }
}