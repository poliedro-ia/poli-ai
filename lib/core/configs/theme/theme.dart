import 'package:flutter/material.dart';
import 'package:app/core/configs/theme/colors.dart';

class AppTheme {
  static ThemeData _base({required bool dark}) {
    final scheme = dark
        ? ColorScheme.dark(
            primary: AppColors.blue,
            surface: const Color(0xff121528),
            onSurface: Colors.white,
          )
        : ColorScheme.light(
            primary: AppColors.blue,
            surface: Colors.white,
            onSurface: const Color(0xff0B1220),
          );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xff0B0E19) : AppColors.white,
      fontFamily: 'BrandingSF', // <- AQUI: fonte global
    );

    // Ajustes de componentes (opcional)
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: dark ? const Color(0xff101425) : Colors.white,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static final light = _base(dark: false);
  static final dark = _base(dark: true);
}
