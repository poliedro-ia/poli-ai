import 'package:flutter/material.dart';
import 'package:app/core/configs/assets/images.dart';

class AuthPalette {
  final bool dark;
  const AuthPalette(this.dark);

  Color get bg => dark ? const Color(0xff0B0E19) : const Color(0xffF7F8FA);
  Color get card => dark ? const Color(0xff121528) : Colors.white;
  Color get border => dark ? const Color(0xff1E2233) : const Color(0xffE5EAF3);
  Color get textMain => dark ? Colors.white : const Color(0xff0B1220);
  Color get textSub => dark ? const Color(0xff99A3BC) : const Color(0xff5A6477);
  Color get fieldBg => dark ? const Color(0xff0F1220) : Colors.white;
  Color get fieldBorder =>
      dark ? const Color(0xff23263A) : const Color(0xffE5EAF3);
  Color get cta => const Color(0xff2563EB);
  Color get barBg => dark ? const Color(0xff101425) : Colors.white;

  InputDecoration dec(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      hintStyle: TextStyle(color: textSub),
      labelStyle: TextStyle(color: textSub),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cta, width: 1.4),
      ),
    );
  }
}

class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AuthPalette p;
  final String actionText;
  final VoidCallback? onAction;
  const AuthAppBar({
    super.key,
    required this.p,
    required this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: p.barBg,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 76,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Image.asset(
            p.dark ? Images.whiteLogo : Images.logo,
            height: 100,
            width: 100,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: p.cta,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(actionText),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: p.border.withOpacity(0.7)),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(76);
}

class AuthCard extends StatelessWidget {
  final AuthPalette p;
  final Widget child;
  const AuthCard({super.key, required this.p, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: [
          if (!p.dark)
            const BoxShadow(
              color: Color(0x11000000),
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
        ],
      ),
      child: child,
    );
  }
}
