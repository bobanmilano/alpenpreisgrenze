// lib/widgets/info_message.dart
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';
import '../models/price_entry.dart';
import '../utils/price_utils.dart'; // Importiere die Hilfsfunktionen

class InfoMessage extends StatelessWidget {
  final List<PriceEntry> allPrices;

  const InfoMessage({Key? key, required this.allPrices}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('InfoMessage neu gerendert'); // Debug-Ausgabe

    if (allPrices.length < 2) {
      return Padding(
        // Füge Padding hinzu, um horizontalen Abstand zum Rand zu schaffen
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Card(
          color: AppColors.primary.withOpacity(0.2), // Hellblauer Hintergrund
          margin: EdgeInsets.zero, // Kein äußerer Rand mehr für die Card
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppRadius.large,
            ), // Abgerundete Ecken
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.s), // Verwenden Sie konsistentes Padding (z.B. 8.0)
            child: Text(
              'Keine ausreichenden Daten für einen Preisvergleich.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary, // Schwarze Schrift
                fontSize: AppTypography.body, // Konsistente Schriftgröße
                fontWeight: FontWeight.w500, // Mittlere Schriftstärke
              ),
            ),
          ),
        ),
      );
    }

    final atPrice = allPrices.cast<PriceEntry?>().firstWhere(
      (p) => p?.country == 'Österreich',
      orElse: () => null,
    );
    final dePrice = allPrices.cast<PriceEntry?>().firstWhere(
      (p) => p?.country == 'Deutschland',
      orElse: () => null,
    );

    if (atPrice == null || dePrice == null) {
      return Padding(
        // Füge Padding hinzu, um horizontalen Abstand zum Rand zu schaffen
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Card(
          color: AppColors.primary.withOpacity(0.2), // Hellblauer Hintergrund
          margin: EdgeInsets.zero, // Kein äußerer Rand mehr für die Card
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppRadius.large,
            ), // Abgerundete Ecken
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.m), // Verwenden Sie konsistentes Padding (z.B. 8.0)
            child: Text(
              'Keine ausreichenden Daten für einen Preisvergleich.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary, // Schwarze Schrift
                fontSize: AppTypography.body, // Konsistente Schriftgröße
                fontWeight: FontWeight.w500, // Mittlere Schriftstärke
              ),
            ),
          ),
        ),
      );
    }

    // Berechne den Preis pro Einheit (Liter, kg, etc.)
    double? atPricePerUnit = calculatePricePerUnit(
      atPrice.price,
      atPrice.quantity,
    );
    double? dePricePerUnit = calculatePricePerUnit(
      dePrice.price,
      dePrice.quantity,
    );

    // Hole die Anzeigeeinheit (z. B. "Liter", "kg")
    String? atUnit = getDisplayUnit(atPrice.quantity);
    String? deUnit = getDisplayUnit(dePrice.quantity);

    if (atPricePerUnit != null && dePricePerUnit != null) {
      // Berechne den prozentualen Unterschied relativ zum deutschen Preis
      final priceDiff = atPricePerUnit - dePricePerUnit;
      final priceDiffPercent = (priceDiff / dePricePerUnit) * 100;

      print('Berechneter Preisunterschied: $priceDiffPercent %');

      // Prüfe auf Sizefuscation (unterschiedliche Mengen)
      double? atQuantityNum = parseQuantity(atPrice.quantity);
      double? deQuantityNum = parseQuantity(dePrice.quantity);
      bool sizefuscationDetected = isSizefuscationDetected(
        atQuantityNum,
        deQuantityNum,
      );

      // Bestimme die gemeinsame Einheit für die Anzeige
      String displayUnit = (atUnit ?? deUnit ?? 'Stück');

      // Sammle alle Nachrichten
      List<String> messages = [];

      // Österreich-Aufschlag
      messages.add(
        'Österreich-Aufschlag: ${priceDiffPercent.abs().toStringAsFixed(2)} % pro $displayUnit',
      );

      // Sizefuscation
      if (sizefuscationDetected) {
        String sizeComparison =
            'AT: ${atPrice.quantity} vs. DE: ${dePrice.quantity}';
        messages.add('Achtung SIZEFUSCATION: $sizeComparison');
      }

      // Shrinkflation (nur wenn Mengen unterschiedlich)
      if (atQuantityNum != null &&
          deQuantityNum != null &&
          atQuantityNum < deQuantityNum) {
        double quantityDiff = deQuantityNum - atQuantityNum;
        String? atRegularUnit = getRegularDisplayUnit(atPrice.quantity);
        String? deRegularUnit = getRegularDisplayUnit(dePrice.quantity);

        messages.add(
          'Shrinkflation: ${quantityDiff.toStringAsFixed(0)} ${atRegularUnit ?? deRegularUnit} weniger Inhalt',
        );
      }

      // Theme-basiertes Farbschema
      final theme = Theme.of(context);
      Color bgColor = theme.colorScheme.errorContainer;
      Color iconColor = theme.colorScheme.onErrorContainer;

      return Padding(
        // Füge Padding hinzu, um horizontalen Abstand zum Rand zu schaffen
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Card(
          color: bgColor,
          // Kein äußerer Rand mehr für die Card selbst
          margin: EdgeInsets.zero, // z.B. von 8.0 auf AppSpacing.s (4.0) entfernt
          child: Padding(
            // Reduziertes inneres Padding mit AppSpacing
            padding: EdgeInsets.all(AppSpacing.m), // z.B. von 16.0 auf AppSpacing.m (8.0)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Optional: Reduzierter Abstand nach oben mit AppSpacing
                // SizedBox(height: AppSpacing.s), // z.B. 4.0, oder ganz weglassen
                // Kein fester SizedBox(height: 8) mehr

                // Bullet-Liste
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: messages
                      .map((msg) => _buildBulletItem(msg, iconColor))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Padding(
        // Füge Padding hinzu, um horizontalen Abstand zum Rand zu schaffen
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Card(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
          // Kein äußerer Rand mehr für die Card selbst
          margin: EdgeInsets.zero, // z.B. von 8.0 auf AppSpacing.s entfernt
          child: Padding(
            // Reduziertes Padding auch hier
            padding: EdgeInsets.all(AppSpacing.m), // z.B. von 16.0 auf AppSpacing.m
            child: Text(
              'Preis pro Einheit kann nicht berechnet werden (ungültige Menge).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }

  // Hilfsfunktion für eine Bullet-Zeile
  Widget _buildBulletItem(String text, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning, size: 18, color: iconColor),
        // Reduzierter Abstand zwischen Icon und Text mit AppSpacing
        SizedBox(width: AppSpacing.s), // z.B. von 8.0 auf AppSpacing.s (4.0)
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white, // ✅ Textfarbe auf weiß gesetzt
            ),
          ),
        ),
      ],
    );
  }
}