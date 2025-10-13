import 'package:app/features/auth/auth_service.dart';
import 'package:app/features/history/history_service.dart';
import 'package:app/features/home/image_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app/common/widgets/skeleton.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  int _columnsForWidth(double w) {
    if (w >= 1200) return 4;
    if (w >= 900) return 3;
    if (w >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final uid = authService.value.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Histórico salvo')),
        body: const Center(child: Text('É necessário estar logado.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico salvo')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: HistoryService().userImagesStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _columnsForWidth(
                  MediaQuery.of(context).size.width,
                ),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 16 / 12,
              ),
              itemCount: 8,
              itemBuilder: (_, __) => const Skeleton(height: double.infinity),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('Nenhuma imagem salva ainda.'),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Gerar imagens'),
                  ),
                ],
              ),
            );
          }
          final docs = snapshot.data!.docs;
          return LayoutBuilder(
            builder: (context, constraints) {
              final cols = _columnsForWidth(constraints.maxWidth);
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 16 / 12,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final src = (data['downloadUrl'] as String?) ?? '';
                  final tag = 'cloud_${doc.id}';
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImageViewerPage(
                              src: src,
                              tag: tag,
                              model: data['model'] as String?,
                              prompt: data['prompt'] as String?,
                            ),
                          ),
                        );
                      },
                      child: CachedNetworkImage(
                        imageUrl: src,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 300),
                        placeholder: (_, __) =>
                            const Skeleton(height: double.infinity),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
