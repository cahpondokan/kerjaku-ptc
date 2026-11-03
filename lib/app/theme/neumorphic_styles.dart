import 'package:flutter/material.dart';
import 'package:lembur/app/theme/app_colors.dart';

abstract final class NeumorphicStyles {
  static const radius = 22.0;

  static List<BoxShadow> raised({double blur = 16, double offset = 7}) => [
    BoxShadow(
      color: AppColors.highlight.withAlpha(230),
      offset: Offset(-offset, -offset),
      blurRadius: blur,
    ),
    BoxShadow(
      color: AppColors.shadow.withAlpha(184),
      offset: Offset(offset, offset),
      blurRadius: blur,
    ),
  ];

  static List<BoxShadow> soft({double blur = 10, double offset = 4}) => [
    BoxShadow(
      color: AppColors.highlight.withAlpha(209),
      offset: Offset(-offset, -offset),
      blurRadius: blur,
    ),
    BoxShadow(
      color: AppColors.shadow.withAlpha(140),
      offset: Offset(offset, offset),
      blurRadius: blur,
    ),
  ];
}
