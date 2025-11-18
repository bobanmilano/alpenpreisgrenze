import 'dart:core';

String toProperCase(String input) {
  if (input.isEmpty) return input;

  return input
      .toLowerCase()
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}

String toProperCaseWithAcronyms(String input) {
  if (input.isEmpty) return input;
  return input
      .toLowerCase()
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;

        if (word.length <= 2 && word.toUpperCase() == word) {
          return word.toUpperCase();
        }

        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}
