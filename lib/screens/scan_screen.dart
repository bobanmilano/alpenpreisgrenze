// lib/screens/scan_screen.dart
import 'package:community_material_icon/community_material_icon.dart';
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/screens/barcode_scanner_page.dart';
import '../models/product.dart';
import 'comparison_screen.dart'; // Import für die nächste Seite
import '../services/openfoodfacts_service.dart';
import 'package:my_price_tracker_app/theme/app_theme_config.dart'; // Importieren Sie das Theme

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isLoading = false;

  // Methode zur Verarbeitung des gescannten Barcodes
  void _handleBarcodeScan(String scannedBarcode) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (scannedBarcode.isEmpty) {
        throw Exception('Kein gültiger Barcode erkannt.');
      }

      // Hole Produktinformationen vom OpenFoodFacts-Dienst
      final product = await OpenFoodFactsService.fetchProduct(scannedBarcode);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Überprüfe, ob ein Produkt gefunden wurde
        if (product.barcode != null) {
          // Produkt gefunden -> Navigiere zum Vergleich
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComparisonScreen(product: product, fromScan: true),
            ),
          );
        } else {
          // Produkt nicht gefunden -> Zeige Snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Produkt mit Barcode $scannedBarcode nicht in der OpenFoodFacts-Datenbank gefunden.'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e, s) {
      debugPrint("Fehler beim Scannen: $e\nStack Trace: $s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Abrufen der Produktinformationen: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verwende das Custom-Styling
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Produkt scannen',
          style: textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Hintergrundfarbe oder Bild (optional)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withOpacity(0.2),
                  theme.colorScheme.secondaryContainer.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Mittig positionierter, großer, runder Button
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    if (_isLoading) return; // Verhindere Klicks während des Ladens

                    // Navigiere zur BarcodeScannerPage und warte auf den gescannten Barcode
                    final scannedBarcode = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BarcodeScannerPage()),
                    );

                    if (scannedBarcode != null) {
                      // Verarbeite den gescannten Barcode
                      _handleBarcodeScan(scannedBarcode);
                    }
                  },
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                          )
                        : Icon(
                            CommunityMaterialIcons.barcode_scan,
                            size: 60,
                            color: theme.colorScheme.onPrimary,
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tippe zum Scannen',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}