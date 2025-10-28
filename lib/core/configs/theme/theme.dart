import 'package:app/core/configs/theme/colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static final mobileTheme = ThemeData(
    primaryColor: AppColors.blue,
    scaffoldBackgroundColor: AppColors.white,
    fontFamily: 'BrandingSF',
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        textStyle: const TextStyle(fontSize: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
  );
}
