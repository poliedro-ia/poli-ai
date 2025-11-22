import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:app/common/widgets/smart_image.dart';
import 'package:app/features/history/ui/history_ui.dart';
import 'package:app/features/history/widgets/history_details.dart';

void showHistoryViewer({
  required BuildContext context,
  required HistoryPalette palette,
  required String docId,
  required String? storagePath,
  required String src,
  required String prompt,
  required String model,
  required void Function(String src) onDownload,
  required void Function(String docId, String? storagePath, String src)
  onDelete,
  int startIndex = 0,
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? allDocs,
}) {
  final size = MediaQuery.of(context).size;
  final isWide = size.width >= 900;

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.75),
    builder: (_) {
      if (kIsWeb && allDocs != null && isWide) {
        int current = startIndex;

        String srcAt(int i) {
          final d = allDocs[i].data();
          return (d['downloadUrl'] as String?) ??
              (d['storagePath'] as String?) ??
              (d['src'] as String? ?? '');
        }

        String promptAt(int i) {
          final d = allDocs[i].data();
          return (d['prompt'] as String?) ??
              (d['promptUsado'] as String? ?? '');
        }

        String modelAt(int i) {
          final d = allDocs[i].data();
          return (d['model'] as String?) ?? '';
        }

        String docIdAt(int i) {
          return allDocs[i].id;
        }

        String? storagePathAt(int i) {
          final d = allDocs[i].data();
          return d['storagePath'] as String?;
        }

        return StatefulBuilder(
          builder: (context, setS) {
            void go(int dir) {
              final len = allDocs.length;
              final n = (current + dir) % len;
              setS(() => current = n < 0 ? len - 1 : n);
            }

            final curSrc = srcAt(current);
            final curPrompt = promptAt(current);
            final curModel = modelAt(current);
            final curDocId = docIdAt(current);
            final curStoragePath = storagePathAt(current);

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: palette.layer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.20),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(72, 28, 72, 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4,
                              child: Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: palette.dark
                                        ? const Color(0xFF0E1120)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: palette.border.withOpacity(.8),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.12),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: SmartImage(
                                    src: curSrc,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Flexible(
                          flex: 5,
                          child: DetailsPaneWeb(
                            palette: palette,
                            prompt: curPrompt,
                            model: curModel,
                            onDownload: () => onDownload(curSrc),
                            onDelete: () {
                              Navigator.pop(context);
                              onDelete(curDocId, curStoragePath, curSrc);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 18,
                    child: IconButton(
                      tooltip: 'Fechar',
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.textMain.withOpacity(.85),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: palette.overlay,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                        ),
                        tooltip: 'Anterior',
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          size: 28,
                          color: palette.textMain.withOpacity(.85),
                        ),
                        onPressed: () => go(-1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: palette.overlay,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                        ),
                        tooltip: 'Próxima',
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          size: 28,
                          color: palette.textMain.withOpacity(.85),
                        ),
                        onPressed: () => go(1),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }

      final isWideLayout = isWide;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: size.height * 0.9),
          child: Container(
            decoration: BoxDecoration(
              color: palette.layer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: isWideLayout
                ? Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4,
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: palette.dark
                                      ? const Color(0xFF0E1120)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: palette.border.withOpacity(.8),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.12),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: SmartImage(
                                  src: src,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: DetailsPaneMobile(
                          palette: palette,
                          src: src,
                          prompt: prompt,
                          model: model,
                          onDownload: () => onDownload(src),
                          onDelete: () {
                            Navigator.pop(context);
                            onDelete(docId, storagePath, src);
                          },
                          onClose: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4,
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: palette.dark
                                      ? const Color(0xFF0E1120)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: palette.border.withOpacity(.8),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.12),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: SmartImage(
                                  src: src,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DetailsPaneMobile(
                        palette: palette,
                        src: src,
                        prompt: prompt,
                        model: model,
                        onDownload: () => onDownload(src),
                        onDelete: () {
                          Navigator.pop(context);
                          onDelete(docId, storagePath, src);
                        },
                        onClose: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
          ),
        ),
      );
    },
  );
}
