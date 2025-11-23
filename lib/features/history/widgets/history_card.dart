import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app/features/history/ui/history_ui.dart';

class HistoryImageCard extends StatefulWidget {
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
  State<HistoryImageCard> createState() => _HistoryImageCardState();
}

class _HistoryImageCardState extends State<HistoryImageCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(color: p.layer),
                  ),
                ),
                Positioned.fill(
                  child: Image.network(
                    widget.src,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: p.textSub,
                      ),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: p.dark
                              ? const Color(0xC0101425)
                              : const Color(0xCCFFFFFF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: p.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Ampliar',
                              onPressed: widget.onTap,
                              icon: const Icon(Icons.zoom_in_rounded),
                              color: p.textMain,
                            ),
                            if (widget.onDownload != null)
                              IconButton(
                                tooltip: 'Baixar',
                                onPressed: widget.onDownload,
                                icon: const Icon(Icons.download_rounded),
                                color: p.textMain,
                              ),
                            if (widget.onDelete != null)
                              IconButton(
                                tooltip: 'Excluir',
                                onPressed: widget.onDelete,
                                icon: const Icon(Icons.delete_outline_rounded),
                                color: p.textMain,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
