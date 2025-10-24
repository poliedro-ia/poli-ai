import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:app/core/configs/assets/images.dart';
import 'package:app/common/widgets/smart_image.dart';
import 'package:app/core/utils/media_utils.dart';
import 'package:app/features/home/home_page.dart';

class HistoryPage extends StatefulWidget {
  final bool? darkInitial;
  const HistoryPage({super.key, this.darkInitial});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _dark = true;

  @override
  void initState() {
    super.initState();
    _dark = widget.darkInitial ?? true;
  }

  Color get _bg => _dark ? const Color(0xff0B0E19) : const Color(0xffF7F8FA);
  Color get _layer => _dark ? const Color(0xff121528) : Colors.white;
  Color get _border =>
      _dark ? const Color(0xff1E2233) : const Color(0xffE7EAF0);
  Color get _textMain => _dark ? Colors.white : const Color(0xff0B1220);
  Color get _textSub =>
      _dark ? const Color(0xff97A0B5) : const Color(0xff5A6477);
  Color get _barBg => _dark ? const Color(0xff101425) : Colors.white;

  String _fileName([int? i]) =>
      'PoliAI_${DateTime.now().millisecondsSinceEpoch}${i != null ? '_$i' : ''}.png';

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: _barBg,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: kIsWeb ? 76 : kToolbarHeight,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.only(left: kIsWeb ? 20 : 14),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          },
          child: Image.asset(
            _dark ? Images.whiteLogo : Images.logo,
            height: kIsWeb ? 100 : 82,
            width: kIsWeb ? 100 : 82,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: kIsWeb ? 14 : 10),
          child: IconButton(
            tooltip: _dark ? 'Tema claro' : 'Tema escuro',
            onPressed: () => setState(() => _dark = !_dark),
            icon: Icon(
              _dark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              color: _textMain,
              size: kIsWeb ? 24 : 22,
            ),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(10),
              backgroundColor: _dark
                  ? const Color(0x221E2A4A)
                  : const Color(0x22E9EEF9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border.withOpacity(0.7)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(),
      body: u == null ? _requireLogin() : _gridFor(u.uid),
    );
  }

  Widget _requireLogin() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, color: _textSub, size: 48),
            const SizedBox(height: 12),
            Text(
              'Entre para visualizar seu histórico',
              style: TextStyle(
                color: _textMain,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suas imagens geradas aparecerão aqui.',
              style: TextStyle(color: _textSub),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridFor(String uid) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('images')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (_, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Erro: ${snap.error}',
              style: TextStyle(color: _textMain),
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
              style: TextStyle(color: _textSub),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            int cross = 2;
            if (w >= 1400)
              cross = 6;
            else if (w >= 1200)
              cross = 5;
            else if (w >= 900)
              cross = 4;
            else if (w >= 640)
              cross = 3;

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
                final src =
                    (d['downloadUrl'] as String?) ??
                    (d['url'] as String?) ??
                    (d['src'] as String? ?? '');
                final prompt =
                    (d['prompt'] as String?) ??
                    (d['promptUsado'] as String? ?? '');
                final model = (d['model'] as String?) ?? '';
                final storagePath = (d['storagePath'] as String?) ?? '';
                return _card(
                  id: doc.id,
                  src: src,
                  prompt: prompt,
                  model: model,
                  storagePath: storagePath,
                  index: i,
                  uid: uid,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _card({
    required String id,
    required String uid,
    required String src,
    required String prompt,
    required String model,
    required String storagePath,
    required int index,
  }) {
    return InkWell(
      onTap: () => _openViewer(id, uid, src, prompt, model, storagePath),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: _layer,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned.fill(
                child: SmartImage(src: src, fit: BoxFit.cover),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Ampliar',
                        onPressed: () => _openViewer(
                          id,
                          uid,
                          src,
                          prompt,
                          model,
                          storagePath,
                        ),
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                      ),
                      IconButton(
                        tooltip: 'Baixar',
                        onPressed: () async {
                          await downloadImage(src, filename: _fileName(index));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Imagem salva')),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: () => _confirmDelete(id, uid, storagePath),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String id, String uid, String storagePath) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AlertDialog(
        title: const Text('Remover imagem'),
        content: const Text('Deseja apagar a imagem do seu histórico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _deleteImage(id: id, uid: uid, storagePath: storagePath);
  }

  Future<void> _deleteImage({
    required String id,
    required String uid,
    required String storagePath,
  }) async {
    try {
      if (storagePath.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref(storagePath).delete();
        } catch (_) {}
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('images')
          .doc(id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Imagem removida')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao apagar: $e')));
      }
    }
  }

  void _openViewer(
    String id,
    String uid,
    String src,
    String prompt,
    String model,
    String storagePath,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 900;
              return Container(
                decoration: BoxDecoration(
                  color: _layer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                padding: const EdgeInsets.all(12),
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 4,
                                child: SmartImage(
                                  src: src,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: _detailsPane(
                              id,
                              uid,
                              src,
                              prompt,
                              model,
                              storagePath,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: SmartImage(src: src, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _detailsPane(
                            id,
                            uid,
                            src,
                            prompt,
                            model,
                            storagePath,
                          ),
                        ],
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _detailsPane(
    String id,
    String uid,
    String src,
    String prompt,
    String model,
    String storagePath,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _dark ? const Color(0xff0F1220) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes',
            style: TextStyle(
              color: _textMain,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (model.isNotEmpty) ...[
            Text(
              'Modelo',
              style: TextStyle(color: _textSub, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(model, style: TextStyle(color: _textMain)),
            const SizedBox(height: 10),
          ],
          Text(
            'Prompt utilizado',
            style: TextStyle(color: _textSub, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            prompt.isEmpty ? 'Indisponível' : prompt,
            style: TextStyle(color: _textMain, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.tonal(
                onPressed: () async {
                  await downloadImage(src, filename: _fileName());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Imagem salva')),
                    );
                  }
                },
                child: const Text('Baixar'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: src));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Link copiado')));
                },
                child: const Text('Copiar link'),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: () => _confirmDelete(id, uid, storagePath),
                icon: const Icon(Icons.delete_outline),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    _dark ? const Color(0xff2A1520) : const Color(0xffFFE8EC),
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    _dark ? const Color(0xffFCA5B1) : const Color(0xffC81E3A),
                  ),
                ),
                tooltip: 'Excluir',
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
