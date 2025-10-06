import 'package:app/core/configs/theme/colors.dart';
import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String title;
  final double? height;
  const AuthButton({
    required this.title,
    this.onPressed,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(height ?? 80),
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          fontFamily: 'BrandingSF',
        ),
        foregroundColor: AppColors.white,
        backgroundColor: AppColors.blue,
      ),
      child: Text(title),
    );
  }
}