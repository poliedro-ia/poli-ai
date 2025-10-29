// ignore_for_file: unused_local_variable

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
  required VoidCallback onDownload,
  required VoidCallback onDelete,
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

        String src0(int i) {
          final d = allDocs[i].data();
          return (d['downloadUrl'] as String?) ??
              (d['storagePath'] as String?) ??
              (d['src'] as String? ?? '');
        }

        String prompt0(int i) {
          final d = allDocs[i].data();
          return (d['prompt'] as String?) ??
              (d['promptUsado'] as String? ?? '');
        }

        String model0(int i) {
          final d = allDocs[i].data();
          return (d['model'] as String?) ?? '';
        }

        String? storage(int i) {
          final d = allDocs[i].data();
          return d['storagePath'] as String?;
        }

        return StatefulBuilder(
          builder: (context, setS) {
            void go(int dir) {
              final next = (current + dir) % allDocs.length;
              setS(() => current = next < 0 ? allDocs.length - 1 : next);
            }

            final curSrc = src0(current);
            final curPrompt = prompt0(current);
            final curModel = model0(current);
            final curId = allDocs[current].id;
            final curStorage = storage(current);

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: palette.layer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.border),
                    ),
                    padding: const EdgeInsets.fromLTRB(56, 32, 56, 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4,
                              child: Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: palette.border.withOpacity(.8),
                                      width: 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SmartImage(
                                      src: curSrc,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Flexible(
                          flex: 5,
                          child: DetailsPaneWeb(
                            palette: palette,
                            prompt: curPrompt,
                            model: curModel,
                            onDownload: onDownload,
                            onDelete: () {
                              Navigator.pop(context);
                              onDelete();
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
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        tooltip: 'Anterior',
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          size: 32,
                          color: palette.textMain.withOpacity(.85),
                        ),
                        onPressed: () => go(-1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        tooltip: 'Próxima',
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          size: 32,
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            padding: const EdgeInsets.all(12),
            child: isWideLayout
                ? Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4,
                            child: Center(
                              child: SmartImage(src: src, fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: DetailsPaneMobile(
                          palette: palette,
                          src: src,
                          prompt: prompt,
                          model: model,
                          onDelete: onDelete,
                          onClose: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4,
                            child: Center(
                              child: SmartImage(src: src, fit: BoxFit.contain),
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
                        onDelete: onDelete,
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
