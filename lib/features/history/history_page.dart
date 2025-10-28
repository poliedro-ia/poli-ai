import 'package:app/core/utils/media_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:app/features/history/ui/history_ui.dart';
import 'package:app/features/history/widgets/history_card.dart';
import 'package:app/features/history/widgets/viewer_dialog.dart';

class HistoryPage extends StatefulWidget {
  final bool? darkInitial;
  const HistoryPage({super.key, this.darkInitial});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late bool _dark;

  @override
  void initState() {
    super.initState();
    _dark = widget.darkInitial ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    final p = HistoryPalette(_dark);
    return Scaffold(
      backgroundColor: p.bg,
      appBar: historyAppBar(
        context: context,
        palette: p,
        onToggleTheme: () => setState(() => _dark = !_dark),
      ),
      body: u == null ? _requireLogin(p) : _gridFor(p, u.uid),
    );
  }

  Widget _requireLogin(HistoryPalette p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, color: p.textSub, size: 48),
            const SizedBox(height: 12),
            Text(
              'Entre para visualizar seu histórico',
              style: TextStyle(
                color: p.textMain,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suas imagens geradas aparecerão aqui.',
              style: TextStyle(color: p.textSub),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridFor(HistoryPalette p, String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('images')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Erro: ${snap.error}',
              style: TextStyle(color: p.textMain),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'Nenhuma imagem ainda',
              style: TextStyle(color: p.textSub),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            int cross = 2;
            if (w >= 1400) {
              cross = 6;
            } else if (w >= 1200) {
              cross = 5;
            } else if (w >= 900) {
              cross = 4;
            } else if (w >= 640) {
              cross = 3;
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final doc = docs[i];
                final d = doc.data();
                final id = doc.id;
                final src =
                    (d['downloadUrl'] as String?) ??
                    (d['storagePath'] as String?) ??
                    (d['src'] as String? ?? '');
                final prompt =
                    (d['prompt'] as String?) ??
                    (d['promptUsado'] as String? ?? '');
                final model = (d['model'] as String?) ?? '';
                final storagePath = d['storagePath'] as String?;

                return HistoryImageCard(
                  palette: p,
                  src: src,
                  onTap: () => _openViewer(
                    palette: p,
                    docId: id,
                    storagePath: storagePath,
                    src: src,
                    prompt: prompt,
                    model: model,
                    startIndex: i,
                    allDocs: docs,
                  ),
                  onDownload: kIsWeb
                      ? () => downloadImage(
                          src,
                          filename:
                              'PoliAI_${DateTime.now().millisecondsSinceEpoch}.png',
                        )
                      : null,
                  onDelete: () => _confirmDelete(id, storagePath, src),
                );
              },
            );
          },
        );
      },
    );
  }

  void _openViewer({
    required HistoryPalette palette,
    required String docId,
    required String? storagePath,
    required String src,
    required String prompt,
    required String model,
    int startIndex = 0,
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? allDocs,
  }) {
    showHistoryViewer(
      context: context,
      palette: palette,
      docId: docId,
      storagePath: storagePath,
      src: src,
      prompt: prompt,
      model: model,
      startIndex: startIndex,
      allDocs: allDocs,
      onDownload: () => downloadImage(
        src,
        filename: 'PoliAI_${DateTime.now().millisecondsSinceEpoch}.png',
      ),
      onDelete: () {
        Navigator.pop(context);
        _confirmDelete(docId, storagePath, src);
      },
    );
  }

  Future<void> _confirmDelete(
    String docId,
    String? storagePath,
    String src,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover imagem?'),
        content: const Text('A imagem será removida do seu histórico.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _deleteImage(uid, docId, storagePath: storagePath, downloadUrl: src);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Imagem removida.')));
    }
  }

  Future<void> _deleteImage(
    String uid,
    String docId, {
    String? storagePath,
    String? downloadUrl,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('images')
          .doc(docId)
          .delete();
    } catch (_) {}
    try {
      if (storagePath != null && storagePath.isNotEmpty) {
        await FirebaseStorage.instance.ref(storagePath).delete();
      } else if ((downloadUrl ?? '').startsWith('https://')) {
        await FirebaseStorage.instance.refFromURL(downloadUrl!).delete();
      }
    } catch (_) {}
  }
}
