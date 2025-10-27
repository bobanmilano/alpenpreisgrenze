// lib/widgets/price_content.dart
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/utils/price_utils.dart';
import '../models/price_entry.dart';

/// Ein Widget zur Darstellung des Inhalts einer Preiskarte (Preis, Menge, Logo, Bild).
class PriceContent extends StatelessWidget {
  final PriceEntry priceEntry;

  const PriceContent({Key? key, required this.priceEntry}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    double? pricePerKg = calculatePricePerUnit(
      priceEntry.price,
      priceEntry.quantity,
    );
    String priceText = '€${priceEntry.price.toStringAsFixed(2)}';
    if (pricePerKg != null) {
      priceText += '\n(€${pricePerKg.toStringAsFixed(2)}/${getUnitFromQuantity(priceEntry.quantity)})';
    }

    // Hole den aktuellen Theme-Textstil für den Hauptpreis
    final TextStyle? headlineStyle = Theme.of(
      context,
    ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              priceText.split('\n')[0],
              style: headlineStyle, // Verwende den definierten Stil
            ),
            SizedBox(width: 8.0), // Reduziert
            if (priceEntry.quantity != null && priceEntry.quantity!.isNotEmpty)
              Text(
                '(${priceEntry.quantity})',
                style: headlineStyle?.copyWith(
                  fontWeight: FontWeight.normal,
                  // Setze die Schriftgröße auf die Hälfte der Hauptpreisgröße
                  fontSize: (headlineStyle?.fontSize ?? 14.0) * 0.5,
                ),
              ),
          ],
        ),
        if (pricePerKg != null)
          Text(
            // ignore: unnecessary_null_comparison
            '(€' + pricePerKg.toStringAsFixed(2) + '/' + getDisplayUnit(priceEntry.quantity)! + ')', 
            //priceEntry.quantity!,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        SizedBox(height: 4), // Reduziert
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildStoreLogoOrText(context, priceEntry.store)],
        ),
        SizedBox(height: 4), // Reduziert
 
        if (priceEntry.productImageURL != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: GestureDetector(
              // ✅ Neuer Wrapper
              onTap: () {
                _showFullImage(context, priceEntry.productImageURL!);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  priceEntry.productImageURL!,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported, size: 50);
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: InteractiveViewer(
                    // ✅ Zoom- und Scroll-Funktion
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image_not_supported, size: 100);
                      },
                    ),
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(), // Schließen
                  child: Text('Schließen'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoreLogoOrText(BuildContext context, String storeName) {
    String lowerCaseName = storeName.toLowerCase();
    if (lowerCaseName == 'aldisüd') {
      lowerCaseName = 'aldisued';
    }
    String logoPath = 'assets/logos/$lowerCaseName.jpg';
    String logoPathUpper = 'assets/logos/$lowerCaseName.JPG';

    return Image.asset(
      logoPath,
      height: 32, // Geringere Höhe
      width: 72, // Geringere Breite
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          logoPathUpper,
          height: 32, // Geringere Höhe
          width: 72, // Geringere Breite
          errorBuilder: (context, error, stackTrace) {
            return Text(
              storeName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            );
          },
        );
      },
    );
  }
}
