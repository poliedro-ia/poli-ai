import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class HomePalette {
  final bool dark;
  const HomePalette(this.dark);

  Color get bg => dark ? const Color(0xff020617) : const Color(0xffF3F4F6);
  Color get layer => dark ? const Color(0xff020617) : Colors.white;
  Color get border => dark ? const Color(0xff1F2937) : const Color(0xffE5E7EB);
  Color get text => dark ? Colors.white : const Color(0xff0B1220);
  Color get subText => dark ? const Color(0xff9CA3AF) : const Color(0xff6B7280);
  Color get fieldBg => dark ? const Color(0xff020617) : const Color(0xffF9FAFB);
  Color get fieldBorder =>
      dark ? const Color(0xff111827) : const Color(0xffD1D5DB);
  Color get barBg => dark ? const Color(0xff020617) : Colors.white;
  Color get cta => const Color(0xff2563EB);

  EdgeInsets get blockPad => EdgeInsets.all(kIsWeb ? 28 : 20);
}

class HomeDeco {
  static InputDecoration select(String label, HomePalette p) {
    final focus = p.cta;
    final labelColor = p.subText;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor),
      floatingLabelStyle: TextStyle(
        color: focus,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      filled: true,
      fillColor: p.fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: focus, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static InputDecoration input({
    required String label,
    required String hint,
    required HomePalette p,
  }) {
    final focus = p.cta;
    final labelColor = p.subText;
    final hintColor = p.dark
        ? const Color(0xff6B7280)
        : const Color(0xff9CA3AF);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: labelColor),
      floatingLabelStyle: TextStyle(
        color: focus,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      hintStyle: TextStyle(color: hintColor),
      filled: true,
      fillColor: p.fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: focus, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }
}
