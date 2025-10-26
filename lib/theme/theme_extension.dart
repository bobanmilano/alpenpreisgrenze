// lib/theme/theme_extension.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';

class CustomColors extends ThemeExtension<CustomColors> {
  final Color starColor;
  final Color ratingHigh;
  final Color ratingMedium;
  final Color ratingLow;

  const CustomColors({
    required this.starColor,
    required this.ratingHigh,
    required this.ratingMedium,
    required this.ratingLow,
  });

  @override
  CustomColors copyWith({
    Color? starColor,
    Color? ratingHigh,
    Color? ratingMedium,
    Color? ratingLow,
  }) {
    return CustomColors(
      starColor: starColor ?? this.starColor,
      ratingHigh: ratingHigh ?? this.ratingHigh,
      ratingMedium: ratingMedium ?? this.ratingMedium,
      ratingLow: ratingLow ?? this.ratingLow,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      starColor: Color.lerp(starColor, other.starColor, t)!,
      ratingHigh: Color.lerp(ratingHigh, other.ratingHigh, t)!,
      ratingMedium: Color.lerp(ratingMedium, other.ratingMedium, t)!,
      ratingLow: Color.lerp(ratingLow, other.ratingLow, t)!,
    );
  }
}