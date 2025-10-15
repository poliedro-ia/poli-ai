import 'package:flutter/material.dart';

class WebNavbar extends StatelessWidget {
  final Widget logo;
  final VoidCallback onHistory;
  final VoidCallback onLogin;
  final VoidCallback cta;
  final bool isDark;

  const WebNavbar({
    super.key,
    required this.logo,
    required this.onHistory,
    required this.onLogin,
    required this.cta,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xff0B0E19) : Colors.white;
    final border = isDark ? const Color(0xff1E2233) : const Color(0xffE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xff111827);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          logo,
          const Spacer(),
          TextButton(
            onPressed: cta,
            style: TextButton.styleFrom(
              foregroundColor: textColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Criar'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onHistory,
            style: TextButton.styleFrom(
              foregroundColor: textColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Histórico'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onLogin,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
