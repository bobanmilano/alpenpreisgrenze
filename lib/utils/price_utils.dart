/// Parst die Menge aus einem String und gibt sie als double zurueck.
double? parseQuantity(String? quantityString) {
  if (quantityString == null || quantityString.isEmpty) return null;
  // Einfacher Regex, um die erste Zahl (ganzzahlig oder dezimal) zu finden
  final regExp = RegExp(r'\d+\.?\d*');
  final match = regExp.firstMatch(quantityString);
  if (match != null) {
    try {
      // Versuche, den gefundenen String in eine Zahl umzuwandeln
      return double.tryParse(match.group(0)!);
    } catch (e) {
      // Logge den Fehler fuer Debugging-Zwecke
      print("Fehler beim Parsen der Menge: $quantityString, Fehler: $e");
      return null;
    }
  }
  return null;
}

/// Berechnet den Preis pro Kilogramm basierend auf dem Gesamtpreis und der Mengenangabe.
double? calculatePricePerKg(double price, String? quantityString) {
  // Pruefe, ob eine Mengenangabe ueberhaupt vorliegt
  if (quantityString == null || quantityString.isEmpty) return null;

  // Versuche, die Menge zu parsen
  double? quantityNum = parseQuantity(quantityString);
  if (quantityNum == null) return null;

  // Konvertiere Gramm in Kilogramm
  double quantityInKg = quantityNum / 1000.0;
  // Vermeide Division durch 0 oder negative Mengen
  if (quantityInKg <= 0) return null;

  // Berechne und gib den Kilopreis zurueck
  return price / quantityInKg;
}

// Falls die Datei bereits andere Funktionen enthält, füge dies hinzu:
String? getDisplayUnit(String? quantity) {
  if (quantity == null || quantity.isEmpty) return null;

  final regex = RegExp(r'[a-zA-Z]+');
  final match = regex.firstMatch(quantity);

  if (match == null) return null;

  final unit = match.group(0)!.toLowerCase();

  switch (unit) {
    case 'ml':
    case 'cl':
    case 'l':
      return 'Liter';
    case 'g':
    case 'kg':
      return 'kg';
    default:
      return unit;
  }
}

String? getRegularDisplayUnit(String? quantity) {
  if (quantity == null || quantity.isEmpty) return null;

  final regex = RegExp(r'[a-zA-Z]+');
  final match = regex.firstMatch(quantity);

  if (match == null) return null;

  final unit = match.group(0)!.toLowerCase();

  return unit;

}


// lib/utils/price_utils.dart

// Prüft, ob die Mengen stark unterschiedlich sind
bool isSizefuscationDetected(
  double? atQuantity,
  double? deQuantity, {
  double threshold = 0.1,
}) {
  if (atQuantity == null || deQuantity == null) return false;

  // Unterschied in %
  double diffPercent = ((atQuantity - deQuantity) / deQuantity).abs();

  return diffPercent > threshold; // z. B. 10 % Unterschied
}

// Gibt den Mengenvergleich als Text zurück
String getSizeComparisonText(
  double? atQuantity,
  String? atUnit,
  double? deQuantity,
  String? deUnit,
) {
  if (atQuantity == null || deQuantity == null) return '';

  String atDisplay = atUnit != null
      ? '${atQuantity.toStringAsFixed(2)} $atUnit'
      : atQuantity.toString();
  String deDisplay = deUnit != null
      ? '${deQuantity.toStringAsFixed(2)} $deUnit'
      : deQuantity.toString();

  return 'Mengenvergleich: AT: $atDisplay vs. DE: $deDisplay';
}

String? getUnitFromQuantity(String? quantity) {
  if (quantity == null || quantity.isEmpty) return null;

  final regex = RegExp(r'[a-zA-Z]+');
  final match = regex.firstMatch(quantity);

  if (match == null) return null;

  return match.group(0);
}

  String? formatMonthYear(DateTime dateTime) {
    // Liste der Monatsnamen
    const List<String> monthNames = [
      "Januar", "Februar", "März", "April", "Mai", "Juni",
      "Juli", "August", "September", "Oktober", "November", "Dezember"
    ];
    // Rückgabe: "Monatsname Jahr"
    return "${monthNames[dateTime.month - 1]} ${dateTime.year}";
  }

double? calculatePricePerUnit(double price, String? quantity) {
  if (quantity == null || quantity.isEmpty) return null;

  final regex = RegExp(r'(\d+\.?\d*)\s*([a-zA-Z]+)'); // Zahlen + Einheit
  final match = regex.firstMatch(quantity);

  if (match == null) return null;

  final value = double.tryParse(match.group(1)!);
  final unit = match.group(2)!.toLowerCase();

  if (value == null) return null;

  switch (unit) {
    case 'ml': // Milliliter → Preis pro Liter
      return (price / value) * 1000;
    case 'cl': // Zentiliter → Preis pro Liter
      return (price / value) * 100;
    case 'l': // Liter
      return price / value;
    case 'mg': // Milligramm → Preis pro kg
      return (price / value) * 1000000;
    case 'g': // Gramm → Preis pro kg
      return (price / value) * 1000;
    case 'kg': // Kilogramm
      return price / value;
    case 't': // Tonne → Preis pro kg
      return (price / value) / 1000;
    default:
      return null; // Unbekannte Einheit
  }
}
