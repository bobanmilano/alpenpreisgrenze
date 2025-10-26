// lib/widgets/product_list_item.dart
import 'package:flutter/material.dart';

class ProductListItem extends StatelessWidget {
  final String? productImageUrl;
  final String? productName;
  final String? manufacturer;
  final double? price;
  final String? storeName;
  final String? city; // ✅ Neues Argument für die Stadt
  final VoidCallback onTap;

  const ProductListItem({
    Key? key,
    this.productImageUrl,
    this.productName,
    this.manufacturer,
    this.price,
    this.storeName,
    this.city, // ✅ Hinzugefügtes Argument
    required this.onTap,
  }) : super(key: key);

  Widget _buildStoreLogoOrText(BuildContext context, String storeName) {
    String lowerCaseName = storeName.toLowerCase();
    if (lowerCaseName == 'aldisüd') {
      lowerCaseName = 'aldisued';
    }
    String logoPathJpg = 'assets/logos/$lowerCaseName.jpg';
    String logoPathJpgUpper = 'assets/logos/$lowerCaseName.JPG';
    String logoOriginal = 'assets/logos/$storeName.jpg'; // ✅ Originalname
    String logoOriginalUpper = 'assets/logos/$storeName.JPG'; // ✅ Originalname

    return Image.asset(
      logoOriginal,
      height: 32,
      width: 72,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          logoOriginalUpper,
          height: 32,
          width: 72,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              logoPathJpg,
              height: 32,
              width: 72,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  logoPathJpgUpper,
                  height: 32,
                  width: 72,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      storeName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (productImageUrl != null)
                Image.network(
                  productImageUrl!,
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported, size: 40);
                  },
                )
              else
                Icon(Icons.image_not_supported, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName ?? 'Unbekanntes Produkt',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('Hersteller: ${manufacturer ?? 'N/A'}'),
                    Text('Preis: €${price?.toStringAsFixed(2) ?? 'N/A'}'),
                    // ✅ Neue Zeile: Shop-Logo/Text und Stadt nebeneinander
                    Row(
                      children: [
                        Flexible(
                          child: _buildStoreLogoOrText(
                            context,
                            storeName ?? 'N/A',
                          ),
                        ),
                        const SizedBox(width: 8), // Kleiner Abstand
                // In der Row, wo Shop und Stadt angezeigt werden
Flexible(
  child: Text(
    (city != null && city!.isNotEmpty) ? city! : 'N/A', // ✅ Prüft auf null und Leerstring
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
  ),
),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
