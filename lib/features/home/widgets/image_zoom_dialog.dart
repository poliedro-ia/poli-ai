import 'dart:math' as math;
import 'package:flutter/material.dart';

class ZoomPalette {
  final Color layer, border, subText;
  const ZoomPalette({
    required this.layer,
    required this.border,
    required this.subText,
  });
}

Future<void> showImageZoomDialog({
  required BuildContext context,
  required String url,
  required ZoomPalette palette,
  required VoidCallback onDownload,
}) async {
  final size = MediaQuery.of(context).size;
  final maxW = math.min(size.width - 24, 1400.0).toDouble();
  final maxH = size.height - 24;

  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.75),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: Container(
          decoration: BoxDecoration(
            color: palette.layer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(
                    builder: (_, c) {
                      final w = c.maxWidth;
                      final h = c.maxHeight;
                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4,
                        child: Center(
                          child: SizedBox(
                            width: w,
                            height: h,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              child: Image.network(
                                url,
                                errorBuilder: (_, __, ___) => Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Falha ao carregar a imagem.',
                                    style: TextStyle(color: palette.subText),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onDownload,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Baixar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Fechar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
