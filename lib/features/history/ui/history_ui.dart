import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:app/core/configs/assets/images.dart';
import 'package:app/features/home/home_page.dart';

class HistoryPalette {
  final bool dark;
  const HistoryPalette(this.dark);

  Color get bg => dark ? const Color(0xff0B0E19) : const Color(0xffF7F8FA);
  Color get layer => dark ? const Color(0xff121528) : Colors.white;
  Color get border => dark ? const Color(0xff1E2233) : const Color(0xffE7EAF0);
  Color get textMain => dark ? Colors.white : const Color(0xff0B1220);
  Color get textSub => dark ? const Color(0xff97A0B5) : const Color(0xff5A6477);
  Color get barBg => dark ? const Color(0xff101425) : Colors.white;

  Color get overlay => dark ? const Color(0xAA151827) : const Color(0xCCFFFFFF);
}

PreferredSizeWidget historyAppBar({
  required BuildContext context,
  required HistoryPalette palette,
  required VoidCallback onToggleTheme,
}) {
  return AppBar(
    backgroundColor: palette.barBg,
    elevation: 0,
    automaticallyImplyLeading: false,
    toolbarHeight: kIsWeb ? 76 : kToolbarHeight,
    titleSpacing: 0,
    title: Padding(
      padding: EdgeInsets.only(left: kIsWeb ? 20 : 14),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        },
        child: Image.asset(
          palette.dark ? Images.whiteLogo : Images.logo,
          height: kIsWeb ? 100 : 82,
          width: kIsWeb ? 100 : 82,
        ),
      ),
    ),
    actions: [
      Padding(
        padding: EdgeInsets.only(right: kIsWeb ? 14 : 10),
        child: IconButton(
          onPressed: onToggleTheme,
          icon: Icon(
            palette.dark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
            color: palette.textMain,
            size: kIsWeb ? 24 : 22,
          ),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(10),
            backgroundColor: palette.dark
                ? const Color(0x221E2A4A)
                : const Color(0x22E9EEF9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: palette.border.withOpacity(0.7)),
    ),
  );
}
