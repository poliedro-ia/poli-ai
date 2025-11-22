  import 'package:flutter/foundation.dart' show kIsWeb;
  import 'package:flutter/material.dart';

  class HomePalette {
    final bool dark;
    const HomePalette(this.dark);

    Color get bg => dark ? const Color(0xff0B0E19) : const Color(0xffF7F8FA);
    Color get layer => dark ? const Color(0xff121528) : Colors.white;
    Color get border => dark ? const Color(0xff1E2233) : const Color(0xffE7EAF0);
    Color get text => dark ? Colors.white : const Color(0xff0B1220);
    Color get subText => dark ? const Color(0xff97A0B5) : const Color(0xff5A6477);
    Color get fieldBg => dark ? const Color(0xff0F1220) : Colors.white;
    Color get fieldBorder =>
        dark ? const Color(0xff23263A) : const Color(0xffD8DEE9);
    Color get barBg => dark ? const Color(0xff101425) : Colors.white;
    Color get cta => const Color(0xff2563EB);

    EdgeInsets get blockPad => EdgeInsets.all(kIsWeb ? 28 : 20);
  }

  class HomeDeco {
    static InputDecoration select(String label, HomePalette p) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: p.subText),
        filled: true,
        fillColor: p.fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.cta, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
    }

    static InputDecoration input({
      required String label,
      required String hint,
      required HomePalette p,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: p.subText),
        hintStyle: TextStyle(
          color: p.dark ? const Color(0xff9AA3B6) : const Color(0xff8A93A6),
        ),
        filled: true,
        fillColor: p.fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.cta, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      );
    }
  }
