import 'dart:convert';
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
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Nenhuma imagem gerada ainda',
              style: TextStyle(color: Colors.grey),
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
                    fadeInDuration: const Duration(milliseconds: 300),
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
                icon: const Icon(Icons.download, color: Colors.white),
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
                icon: const Icon(Icons.fullscreen, color: Colors.white),
              ),
            ];

            final actions =
                actionsBuilder?.call(context, src, tag, item, index) ??
                defaultActions();

            return Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(tag: tag, child: preview),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.52),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: actions),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
