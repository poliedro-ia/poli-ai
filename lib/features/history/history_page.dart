import 'package:app/features/auth/auth_service.dart';
import 'package:app/features/history/history_service.dart';
import 'package:app/features/home/image_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma imagem salva ainda.'));
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
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Hero(
                          tag: tag,
                          child: Image.network(src, fit: BoxFit.cover),
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
