import 'package:flutter/material.dart';
import 'package:app/features/history/ui/history_ui.dart';

class HistoryImageCard extends StatelessWidget {
  final HistoryPalette palette;
  final String src;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  const HistoryImageCard({
    super.key,
    required this.palette,
    required this.src,
    this.onTap,
    this.onDownload,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: p.layer)),
            Positioned.fill(
              child: Image.network(
                src,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.broken_image_outlined, color: p.textSub),
                ),
                loadingBuilder: (ctx, child, ev) {
                  if (ev == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: p.dark
                      ? const Color(0xC0101425)
                      : const Color(0xCCFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Ampliar',
                      onPressed: onTap,
                      icon: const Icon(Icons.zoom_in),
                      color: p.textMain,
                    ),
                    if (onDownload != null)
                      IconButton(
                        tooltip: 'Baixar',
                        onPressed: onDownload,
                        icon: const Icon(Icons.download_rounded),
                        color: p.textMain,
                      ),
                    if (onDelete != null)
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        color: p.textMain,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
