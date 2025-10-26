// lib/services/openfoodfacts_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class OpenFoodFactsService {
  static const String baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  static Future<Product> fetchProduct(String barcode) async {
    final response = await http.get(Uri.parse('$baseUrl/$barcode.json'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Product.fromJson(data);
    } else {
      throw Exception('Fehler beim Abrufen des Produkts von OpenFoodFacts');
    }
  }
}