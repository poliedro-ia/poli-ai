import 'package:app/features/auth/auth_service.dart';
import 'package:app/features/history/history_service.dart';
import 'package:app/features/home/image_viewer_page.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

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
      body: StreamBuilder(
        stream: HistoryService().userImagesStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma imagem salva ainda.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final src = (data['downloadUrl'] as String?) ?? '';
              final model = data['model'] as String?;
              final prompt = data['prompt'] as String?;
              final tag = 'cloud_${docs[index].id}';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
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
                          model: model,
                          prompt: prompt,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      if (src.isNotEmpty)
                        Hero(
                          tag: tag,
                          child: Image.network(
                            src,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (model != null) Text(model),
                            if (prompt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                prompt,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
