import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  static const TextStyle heading = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle body = TextStyle(fontSize: 16, color: AppColors.text);

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: AppColors.text,
  );
}
