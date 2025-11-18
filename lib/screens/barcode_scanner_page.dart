import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  late MobileScannerController cameraController = MobileScannerController(
    torchEnabled: false,
  );

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

        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (!isScanning) return;

          final List<Barcode> barcodes = capture.barcodes;

          for (final barcode in barcodes) {
            final String? rawValue = barcode.rawValue;
            if (rawValue != null && rawValue.isNotEmpty) {
              setState(() {
                isScanning = false;
              });

              debugPrint('Barcode erkannt: $rawValue');

              if (context.mounted) {
                Navigator.of(context).pop(rawValue);
              }
              break;
            }
          }
        },
      ),
    );
  }
}
