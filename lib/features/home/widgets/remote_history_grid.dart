import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app/common/widgets/skeleton.dart';
import 'package:app/features/home/image_viewer_page.dart';
import 'package:app/core/utils/media_utils.dart';
import 'package:app/features/home/models/image_item.dart';

class RemoteHistoryGrid extends StatelessWidget {
  final String uid;

  const RemoteHistoryGrid({super.key, required this.uid});

  List<ImageItem> _mapDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((d) {
          final data = d.data();
          final src =
              (data['url'] ?? data['downloadUrl'] ?? data['src'] ?? '')
                  as String;
          final model = data['model'] as String?;
          final prompt =
              data['prompt'] as String? ?? data['promptUsado'] as String?;
          return ImageItem(src: src, model: model, prompt: prompt);
        })
        .where((e) => e.src.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('images')
        .orderBy('createdAt', descending: true)
        .limit(60);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: col.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Skeleton(height: 240);
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
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
                Icon(Icons.photo_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Sem registros ainda',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final items = _mapDocs(snap.data!.docs);
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            int cross = 1;
            if (w >= 1100) {
              cross = 3;
            } else if (w >= 700)
              cross = 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 16 / 10,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final src = item.src;
                final isDataUrl = src.startsWith('data:image/');
                final tag = 'remote_img_$index';
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
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      );

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
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  await downloadImage(
                                    src,
                                    filename: 'eduimage_$index',
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Imagem salva.'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.download,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await shareImage(
                                    src,
                                    filename: 'eduimage_$index',
                                  );
                                },
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.white,
                                ),
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
                                icon: const Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
