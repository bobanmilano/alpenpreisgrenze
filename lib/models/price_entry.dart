import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_price_tracker_app/models/product.dart';
import 'package:my_price_tracker_app/utils/string_utils.dart';

class PriceEntry {
  final String id;
  final String barcode;
  final String productName;
  final String? brands;
  final String? quantity;
  final double price;
  final String userId;
  final String city;
  final String country;
  final String store;
  final String? productImageURL;
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
    this.productImageURL,
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
      productImageURL: map['product_image_url']?.toString(),
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
      'product_image_url': productImageURL,
      'timestamp': timestamp,
    };
  }

  String get displayName => toProperCase(productName);
  String get displayStore => toProperCase(store);
  String get displayCity => toProperCase(city);

  Product toProduct() {
    return Product(
      barcode: barcode,
      productName: productName,
      brands: brands,
      quantity: quantity,
      imageUrl: productImageURL,
    );
  }
}
