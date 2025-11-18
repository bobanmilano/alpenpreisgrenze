double? parseQuantity(String? quantityString) {
  if (quantityString == null || quantityString.isEmpty) return null;

  final regExp = RegExp(r'\d+\.?\d*');
  final match = regExp.firstMatch(quantityString);
  if (match != null) {
    try {
      return double.tryParse(match.group(0)!);
    } catch (e) {
      print("Fehler beim Parsen der Menge: $quantityString, Fehler: $e");
      return null;
    }
  }
  return null;
}

double? calculatePricePerKg(double price, String? quantityString) {
  if (quantityString == null || quantityString.isEmpty) return null;

  double? quantityNum = parseQuantity(quantityString);
  if (quantityNum == null) return null;

  double quantityInKg = quantityNum / 1000.0;

  if (quantityInKg <= 0) return null;

  return price / quantityInKg;
}

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

bool isSizefuscationDetected(
  double? atQuantity,
  double? deQuantity, {
  double threshold = 0.1,
}) {
  if (atQuantity == null || deQuantity == null) return false;

  double diffPercent = ((atQuantity - deQuantity) / deQuantity).abs();

  return diffPercent > threshold;
}

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
  const List<String> monthNames = [
    "Januar",
    "Februar",
    "März",
    "April",
    "Mai",
    "Juni",
    "Juli",
    "August",
    "September",
    "Oktober",
    "November",
    "Dezember",
  ];

  return "${monthNames[dateTime.month - 1]} ${dateTime.year}";
}

double? calculatePricePerUnit(double price, String? quantity) {
  if (quantity == null || quantity.isEmpty) return null;

  final regex = RegExp(r'(\d+\.?\d*)\s*([a-zA-Z]+)');
  final match = regex.firstMatch(quantity);

  if (match == null) return null;

  final value = double.tryParse(match.group(1)!);
  final unit = match.group(2)!.toLowerCase();

  if (value == null) return null;

  switch (unit) {
    case 'ml':
      return (price / value) * 1000;
    case 'cl':
      return (price / value) * 100;
    case 'l':
      return price / value;
    case 'mg':
      return (price / value) * 1000000;
    case 'g':
      return (price / value) * 1000;
    case 'kg':
      return price / value;
    case 't':
      return (price / value) / 1000;
    default:
      return null;
  }
}
