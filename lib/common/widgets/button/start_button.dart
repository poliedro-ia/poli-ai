import 'package:app/core/configs/theme/colors.dart';
import 'package:flutter/material.dart';

class StartButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;
  final double? height;
  const StartButton({
    required this.onPressed,
    required this.title,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(height ?? 90),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        foregroundColor: Colors.white,
        backgroundColor: AppColors.orange,
      ),
      child: Text(title),
    );
  }
}
