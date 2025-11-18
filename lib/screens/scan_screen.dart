import 'package:community_material_icon/community_material_icon.dart';
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/screens/barcode_scanner_page.dart';
import 'package:my_price_tracker_app/services/firebase_service.dart';
import 'package:my_price_tracker_app/utils/app_constants.dart';
import '../models/product.dart';
import 'comparison_screen.dart';
import '../services/openfoodfacts_service.dart';
import 'package:my_price_tracker_app/theme/app_theme_config.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isLoading = false;
  final TextEditingController _barcodeController = TextEditingController();
  static const String _adminUserId = AppConstants.adminUserId;
  final FirebaseService _firebaseService = FirebaseService();

  String? _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final userId = _firebaseService.getCurrentUserId();
      if (mounted) {
        setState(() {
          _currentUserId = userId;
        });
      }
    } catch (e) {
      print('Fehler beim Laden der User-ID: $e');
    }
  }

  void _handleBarcodeScan(String scannedBarcode) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (scannedBarcode.isEmpty) {
        throw Exception('Kein gültiger Barcode erkannt.');
      }

      final product = await OpenFoodFactsService.fetchProduct(scannedBarcode);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (product.barcode != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ComparisonScreen(product: product, fromScan: true),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Produkt mit Barcode $scannedBarcode nicht in der OpenFoodFacts-Datenbank gefunden.',
              ),
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

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    if (_isLoading) return;

                    final scannedBarcode = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BarcodeScannerPage(),
                      ),
                    );

                    if (scannedBarcode != null) {
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
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
                  'Tippe um Scan zu starten',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),

                if (_currentUserId == _adminUserId) ...[
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _barcodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Barcode manuell eingeben',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.send),
                          onPressed: () {
                            final barcode = _barcodeController.text.trim();
                            if (barcode.isNotEmpty) {
                              _handleBarcodeScan(barcode);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Bitte einen Barcode eingeben'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
