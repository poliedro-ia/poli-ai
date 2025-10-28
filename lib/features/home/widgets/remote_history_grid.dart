import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:app/common/widgets/skeleton.dart';
import 'package:app/features/home/models/image_item.dart';
import 'package:app/features/home/widgets/image_grid.dart';

class RemoteHistoryGrid extends StatelessWidget {
  final String uid;
  final int limit;
  const RemoteHistoryGrid({super.key, required this.uid, this.limit = 60});

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
        .limit(limit);

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
        return ImageGrid(images: items, heroPrefix: 'remote_img');
      },
    );
  }
}
