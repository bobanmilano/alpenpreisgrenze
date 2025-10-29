// lib/utils/string_utils.dart
import 'dart:core';

/// Wandelt einen String in 'Proper Case' um.
/// Jedes Wort beginnt mit einem Großbuchstaben.
/// Beispiel: 'mezzo mix' -> 'Mezzo Mix'
/// Beispiel: 'WIEN' -> 'Wien'
String toProperCase(String input) {
  if (input.isEmpty) return input;

  // Trenne den String anhand von Leerzeichen (oder anderen gängigen Trennzeichen)
  // Für komplexere Trennzeichen (z.B. Bindestriche) müsste man den Regex anpassen.
  return input.toLowerCase().split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }).join(' ');
}

/// Optional: Funktion, die auch Akronyme wie "AT" oder "DE" berücksichtigt
/// Beispiel: 'österreichische bundesbahnen at' -> 'Österreichische Bundesbahnen AT'
String toProperCaseWithAcronyms(String input) {
  if (input.isEmpty) return input;
  return input.toLowerCase().split(' ').map((word) {
    if (word.isEmpty) return word;
    // Wenn das Wort nur aus Großbuchstaben besteht und 2 Zeichen oder kürzer ist, behalte es in Großbuchstaben
    if (word.length <= 2 && word.toUpperCase() == word) {
      return word.toUpperCase(); // z.B. "at" -> "AT", "de" -> "DE"
    }
    // Sonst: Erstes Zeichen groß, Rest klein
    return word[0].toUpperCase() + word.substring(1);
  }).join(' ');
}