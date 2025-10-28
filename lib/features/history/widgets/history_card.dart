import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:app/common/widgets/smart_image.dart';
import 'package:app/features/history/ui/history_ui.dart';

class HistoryImageCard extends StatelessWidget {
  final HistoryPalette palette;
  final String src;
  final VoidCallback onTap;
  final VoidCallback? onDownload;
  final VoidCallback onDelete;

  const HistoryImageCard({
    super.key,
    required this.palette,
    required this.src,
    required this.onTap,
    required this.onDelete,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: palette.layer,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned.fill(
                child: SmartImage(src: src, fit: BoxFit.cover),
              ),
              if (kIsWeb)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    decoration: const ShapeDecoration(
                      color: Color(0x00000000),
                      shape: StadiumBorder(),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Ampliar',
                          onPressed: onTap,
                          icon: Icon(
                            Icons.fullscreen,
                            color: palette.dark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (onDownload != null)
                          IconButton(
                            tooltip: 'Baixar',
                            onPressed: onDownload,
                            icon: Icon(
                              Icons.download_rounded,
                              color: palette.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Excluir',
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Material(
                    color: palette.overlay,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: palette.dark ? Colors.white : Colors.black87,
                      onPressed: onDelete,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
