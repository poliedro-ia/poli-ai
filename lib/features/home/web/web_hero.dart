import 'package:flutter/material.dart';
import 'badge_item.dart';

class WebHero extends StatelessWidget {
  final List<String> title;
  final String description;
  final String ctaText;
  final VoidCallback onCta;
  final List<BadgeItem> badges;
  final bool isDark;

  const WebHero({
    super.key,
    required this.title,
    required this.description,
    required this.ctaText,
    required this.onCta,
    required this.badges,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.black : Colors.white;
    final textMain = isDark ? Colors.white : const Color(0xff111827);
    final textSub = isDark ? const Color(0xffC8CDD9) : const Color(0xff4B5563);
    final chipBg = isDark ? const Color(0xff0F1220) : const Color(0xffF3F4F6);
    final chipBorder = isDark
        ? const Color(0xff1E2233)
        : const Color(0xffE5E7EB);

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                title.join('\n'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textMain,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1.06,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(color: textSub, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onCta,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 16,
                  ),
                ),
                child: Text(ctaText),
              ),
              const SizedBox(height: 26),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: badges
                    .map(
                      (b) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: chipBorder),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              b.title,
                              style: TextStyle(
                                color: textMain,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(b.subtitle, style: TextStyle(color: textSub)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
