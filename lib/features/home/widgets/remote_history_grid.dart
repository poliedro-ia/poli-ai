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
          final theme = Theme.of(context);
          final cardColor = theme.cardColor;
          final textColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
          textColor.withOpacity(0.65);
          return Container(
            height: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withOpacity(0.25)),
            ),
            child: const _EmptyRemoteHistory(),
          );
        }
        final items = _mapDocs(snap.data!.docs);
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.95, end: 1),
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: ImageGrid(images: items, heroPrefix: 'remote_img'),
        );
      },
    );
  }
}

class _EmptyRemoteHistory extends StatelessWidget {
  const _EmptyRemoteHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final subColor = textColor.withOpacity(0.65);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.photo_outlined, size: 44, color: subColor),
        const SizedBox(height: 8),
        Text(
          'Sem registros ainda',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'Assim que você gerar imagens, elas aparecem aqui.',
          style: TextStyle(color: subColor, fontSize: 13),
        ),
      ],
    );
  }
}
