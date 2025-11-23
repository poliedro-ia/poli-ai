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
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedScale(
          scale: _hover ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(child: Container(color: p.layer)),
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
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _hover ? 0.18 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.35),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: p.dark
                              ? const Color(0xCC0B1020)
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
                              splashRadius: 18,
                            ),
                            if (widget.onDownload != null)
                              IconButton(
                                tooltip: 'Baixar',
                                onPressed: widget.onDownload,
                                icon: const Icon(Icons.download_rounded),
                                color: p.textMain,
                                splashRadius: 18,
                              ),
                            if (widget.onDelete != null)
                              IconButton(
                                tooltip: 'Excluir',
                                onPressed: widget.onDelete,
                                icon: const Icon(Icons.delete_outline_rounded),
                                color: p.textMain,
                                splashRadius: 18,
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
