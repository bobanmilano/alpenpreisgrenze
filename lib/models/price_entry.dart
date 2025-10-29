// lib/models/price_entry.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_price_tracker_app/models/product.dart';
// --- NEU: Importiere die Hilfsfunktion ---
import 'package:my_price_tracker_app/utils/string_utils.dart';

class PriceEntry {
  final String id; // Dokument-ID in Firestore
  final String barcode;
  final String productName;
  final String? brands;
  final String? quantity;
  final double price;
  final String userId;
  final String city;
  final String country;
  final String store;
  final String? productImageURL; // NEU: URL zum Produktbild in Storage
  final DateTime timestamp;

  PriceEntry({
    required this.id,
    required this.barcode,
    required this.productName,
    this.brands,
    this.quantity,
    required this.price,
    required this.userId,
    required this.city,
    required this.country,
    required this.store,
    this.productImageURL, // NEU
    required this.timestamp,
  });

  factory PriceEntry.fromMap(Map<String, dynamic> map, String id) {
    return PriceEntry(
      id: id,
      barcode: map['barcode'] ?? '',
      productName: map['product_name'] ?? '',
      brands: map['brands']?.toString(),
      quantity: map['quantity']?.toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      userId: map['user_id'] ?? '',
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      store: map['store'] ?? '',
      productImageURL: map['product_image_url']?.toString(), // NEU
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'product_name': productName,
      'brands': brands,
      'quantity': quantity,
      'price': price,
      'user_id': userId,
      'city': city,
      'country': country,
      'store': store,
      'product_image_url': productImageURL, // NEU
      'timestamp': timestamp,
    };
  }

  // --- NEU: Getter für "schön formatierte" Strings ---
  String get displayName => toProperCase(productName);
  String get displayStore => toProperCase(store);
  String get displayCity => toProperCase(city);
  // --- ENDE NEU ---

  Product toProduct() {
    return Product(
      barcode: barcode,
      productName: productName, // oder displayName, wenn du es immer schön haben willst
      brands: brands,
      quantity: quantity,
      imageUrl: productImageURL,
    );
  }
}