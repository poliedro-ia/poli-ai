import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:app/common/widgets/skeleton.dart';
import 'package:app/core/utils/media_utils.dart';
import 'package:app/features/home/image_viewer_page.dart';
import 'package:app/features/home/models/image_item.dart';

typedef GridItemActionsBuilder =
    List<Widget> Function(
      BuildContext context,
      String src,
      String tag,
      ImageItem item,
      int index,
    );

class ImageGrid extends StatelessWidget {
  final List<ImageItem> images;
  final String heroPrefix;
  final String filePrefix;
  final GridItemActionsBuilder? actionsBuilder;

  const ImageGrid({
    super.key,
    required this.images,
    this.heroPrefix = 'img',
    this.filePrefix = 'PoliAI',
    this.actionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      final theme = Theme.of(context);
      final cardColor = theme.cardColor;
      final textColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
      final subColor = textColor.withOpacity(0.65);
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 44, color: subColor),
            const SizedBox(height: 8),
            Text(
              'Nenhuma imagem gerada ainda',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'As imagens geradas recentemente aparecem aqui.',
              style: TextStyle(color: subColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        int cross = 1;
        if (w >= 1100) {
          cross = 3;
        } else if (w >= 700) {
          cross = 2;
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 16 / 10,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final item = images[index];
            final src = item.src;
            final isDataUrl = src.startsWith('data:image/');
            final tag = '${heroPrefix}_$index';

            final Widget preview = isDataUrl
                ? Image.memory(
                    base64Decode(src.split(',').last),
                    fit: BoxFit.cover,
                  )
                : CachedNetworkImage(
                    imageUrl: src,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 260),
                    placeholder: (_, __) =>
                        const Skeleton(height: double.infinity),
                    errorWidget: (_, __, ___) =>
                        const Center(child: Icon(Icons.broken_image_outlined)),
                  );

            List<Widget> defaultActions() => [
              IconButton(
                onPressed: () async {
                  await downloadImage(
                    src,
                    filename:
                        '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}_$index.png',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Imagem salva.')),
                    );
                  }
                },
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                splashRadius: 18,
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageViewerPage(
                        src: src,
                        tag: tag,
                        model: item.model,
                        prompt: item.prompt,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
                splashRadius: 18,
              ),
            ];

            final actions =
                actionsBuilder?.call(context, src, tag, item, index) ??
                defaultActions();

            return _ImageTile(tag: tag, preview: preview, actions: actions);
          },
        );
      },
    );
  }
}

class _ImageTile extends StatefulWidget {
  final String tag;
  final Widget preview;
  final List<Widget> actions;

  const _ImageTile({
    required this.tag,
    required this.preview,
    required this.actions,
  });

  @override
  State<_ImageTile> createState() => _ImageTileState();
}

class _ImageTileState extends State<_ImageTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor.withOpacity(0.3);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Hero(tag: widget.tag, child: widget.preview),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.actions,
                      ),
                    ),
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
