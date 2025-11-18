import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LocalLocationService {
  static List<String> _citiesAT = [];
  static List<String> _citiesDE = [];

  static Future<void> loadCities() async {
    try {
      String jsonStringAT = await rootBundle.loadString(
        'assets/cities_at.json',
      );
      Map<String, dynamic> jsonDataAT = json.decode(jsonStringAT);
      List<dynamic> cityListAT = jsonDataAT['cities'] ?? [];
      _citiesAT = cityListAT.cast<String>();
      _citiesAT.sort();

      String jsonStringDE = await rootBundle.loadString(
        'assets/cities_de.json',
      );
      Map<String, dynamic> jsonDataDE = json.decode(jsonStringDE);
      List<dynamic> cityListDE = jsonDataDE['cities'] ?? [];
      _citiesDE = cityListDE.cast<String>();
      _citiesDE.sort();
    } catch (e) {
      print('Fehler beim Laden der Städte-JSONs: $e');
      _citiesAT = [];
      _citiesDE = [];
    }
  }

  static List<String> searchCities(String query, String country) {
    if (query.length < 2) {
      return [];
    }
    String lowerQuery = query.toLowerCase();
    List<String> sourceList = country == 'Österreich' ? _citiesAT : _citiesDE;
    return sourceList
        .where((city) => city.toLowerCase().contains(lowerQuery))
        .toList();
  }

  static List<String> getAllCitiesForCountry(String country) {
    return List.from(country == 'Österreich' ? _citiesAT : _citiesDE);
  }
}
