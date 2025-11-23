import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:app/core/utils/media_utils.dart';
import 'package:app/features/history/history_page.dart';
import 'package:app/features/home/ui/home_ui.dart';

class ResultPanel extends StatelessWidget {
  final HomePalette p;
  final String? previewDataUrlOrUrl;
  final String aspect;
  final VoidCallback onZoom;
  final bool canDownload;

  const ResultPanel({
    super.key,
    required this.p,
    required this.previewDataUrlOrUrl,
    required this.aspect,
    required this.onZoom,
    required this.canDownload,
  });

  double get _ar => aspect == '1:1'
      ? 1
      : (aspect == '4:3'
            ? 4 / 3
            : aspect == '3:2'
            ? 3 / 2
            : aspect == '9:16'
            ? 9 / 16
            : 16 / 9);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.96, end: 1),
      builder: (_, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          color: p.layer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(p.dark ? 0.30 : 0.10),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        padding: p.blockPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultado',
              style: TextStyle(
                color: p.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: kIsWeb ? 12 : 8),
            Text(
              'Sua imagem gerada aparecerá aqui',
              style: TextStyle(color: p.subText),
            ),
            SizedBox(height: kIsWeb ? 16 : 12),
            previewDataUrlOrUrl == null
                ? Container(
                    height: kIsWeb ? 320 : 260,
                    decoration: BoxDecoration(
                      color: p.fieldBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: p.fieldBorder),
                    ),
                    child: Center(
                      child: Text(
                        'Sem imagem ainda',
                        style: TextStyle(color: p.subText),
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: LayoutBuilder(
                      builder: (_, c) {
                        return AspectRatio(
                          aspectRatio: _ar,
                          child: SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: c.maxWidth,
                                height: c.maxWidth / _ar,
                                child: Image.network(
                                  previewDataUrlOrUrl!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            SizedBox(height: kIsWeb ? 20 : 16),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: previewDataUrlOrUrl == null ? null : onZoom,
                  style: FilledButton.styleFrom(
                    backgroundColor: p.dark
                        ? const Color(0xff111827)
                        : const Color(0xffE5EDFF),
                    foregroundColor: p.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 18 : 16,
                      vertical: kIsWeb ? 16 : 14,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Ampliar'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: (!canDownload || previewDataUrlOrUrl == null)
                      ? null
                      : () => downloadImage(
                          previewDataUrlOrUrl!,
                          filename:
                              'PoliAI_${DateTime.now().millisecondsSinceEpoch}.png',
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.dark
                        ? const Color(0xff111827)
                        : const Color(0xffE5EDFF),
                    foregroundColor: p.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 18 : 16,
                      vertical: kIsWeb ? 16 : 14,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Baixar'),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryPage(darkInitial: p.dark),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.dark
                        ? const Color(0xff111827)
                        : const Color(0xffE5EDFF),
                    foregroundColor: p.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 18 : 16,
                      vertical: kIsWeb ? 16 : 14,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_edu_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Ver histórico'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
