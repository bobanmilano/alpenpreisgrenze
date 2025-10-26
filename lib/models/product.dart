// lib/models/product.dart
class Product {
  final String? barcode;
  final String? productName;
  final String? brands;
  final String? quantity;
  final String? imageUrl;

  Product({
    this.barcode,
    this.productName,
    this.brands,
    this.quantity,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'] ?? {};

    return Product(
      barcode: productJson['code'],
      productName: productJson['product_name']?.toString().isNotEmpty == true
          ? productJson['product_name']
          : null,
      brands: productJson['brands']?.toString().isNotEmpty == true
          ? productJson['brands']
          : null,
      quantity: productJson['quantity']?.toString().isNotEmpty == true
          ? productJson['quantity']
          : null,
      imageUrl: productJson['image_url']?.toString().isNotEmpty == true
          ? productJson['image_url']
          : null,
    );
  }
}