import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';
import '../models/price_entry.dart';
import '../utils/price_utils.dart';

class InfoMessage extends StatelessWidget {
  final List<PriceEntry> allPrices;

  const InfoMessage({Key? key, required this.allPrices}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('InfoMessage neu gerendert');

    if (allPrices.length < 2) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Card(
          color: AppColors.primary.withOpacity(0.2),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.s),
            child: Text(
              'Keine ausreichenden Daten für einen Preisvergleich.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w500,
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
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Card(
          color: AppColors.primary.withOpacity(0.2),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.m),
            child: Text(
              'Keine ausreichenden Daten für einen Preisvergleich.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    double? atPricePerUnit = calculatePricePerUnit(
      atPrice.price,
      atPrice.quantity,
    );
    double? dePricePerUnit = calculatePricePerUnit(
      dePrice.price,
      dePrice.quantity,
    );

    String? atUnit = getDisplayUnit(atPrice.quantity);
    String? deUnit = getDisplayUnit(dePrice.quantity);

    if (atPricePerUnit != null && dePricePerUnit != null) {
      final priceDiff = atPricePerUnit - dePricePerUnit;
      final priceDiffPercent = (priceDiff / dePricePerUnit) * 100;

      print('Berechneter Preisunterschied: $priceDiffPercent %');

      double? atQuantityNum = parseQuantity(atPrice.quantity);
      double? deQuantityNum = parseQuantity(dePrice.quantity);
      bool sizefuscationDetected = isSizefuscationDetected(
        atQuantityNum,
        deQuantityNum,
      );

      String displayUnit = (atUnit ?? deUnit ?? 'Stück');

      List<String> messages = [];

      messages.add(
        'Österreich-Aufschlag: ${priceDiffPercent.abs().toStringAsFixed(2)} % pro $displayUnit',
      );

      if (sizefuscationDetected) {
        String sizeComparison =
            'AT: ${atPrice.quantity} vs. DE: ${dePrice.quantity}';
        messages.add('Achtung SIZEFUSCATION: $sizeComparison');
      }

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

      final theme = Theme.of(context);
      Color bgColor = theme.colorScheme.errorContainer;
      Color iconColor = theme.colorScheme.onErrorContainer;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Card(
          color: bgColor,

          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Card(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),

          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.m),
            child: Text(
              'Preis pro Einheit kann nicht berechnet werden (ungültige Menge).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildBulletItem(String text, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning, size: 18, color: iconColor),

        SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
