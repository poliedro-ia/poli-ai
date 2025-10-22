import 'package:app/core/configs/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/core/configs/assets/images.dart';
import 'package:app/common/widgets/smart_image.dart';
import 'package:app/core/utils/media_utils.dart';
import 'package:app/features/home/home_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Color _bg(bool d) => d ? const Color(0xff0B0E19) : const Color(0xffF7F8FA);
  Color _layer(bool d) => d ? const Color(0xff121528) : Colors.white;
  Color _border(bool d) =>
      d ? const Color(0xff1E2233) : const Color(0xffE7EAF0);
  Color _text(bool d) => d ? Colors.white : const Color(0xff0B1220);
  Color _sub(bool d) => d ? const Color(0xff97A0B5) : const Color(0xff5A6477);
  Color _bar(bool d) => d ? const Color(0xff101425) : Colors.white;

  PreferredSizeWidget _appBar(BuildContext context, bool dark) {
    return AppBar(
      backgroundColor: _bar(dark),
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: kIsWeb ? 76 : kToolbarHeight,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.only(left: kIsWeb ? 20 : 14),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          ),
          child: Image.asset(
            dark ? Images.whiteLogo : Images.logo,
            height: kIsWeb ? 100 : 82,
            width: kIsWeb ? 100 : 82,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: kIsWeb ? 14 : 10),
          child: IconButton(
            onPressed: () => ThemeController.instance.toggle(),
            icon: Icon(
              dark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              color: _text(dark),
              size: kIsWeb ? 24 : 22,
            ),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(10),
              backgroundColor: dark
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
        child: Container(height: 1, color: _border(dark).withOpacity(0.7)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDark,
      builder: (_, dark, __) {
        return Scaffold(
          backgroundColor: _bg(dark),
          appBar: _appBar(context, dark),
          body: u == null ? _needLogin(dark) : _gridFor(context, u.uid, dark),
        );
      },
    );
  }

  Widget _needLogin(bool dark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, color: _sub(dark), size: 48),
            const SizedBox(height: 12),
            Text(
              'Entre para visualizar seu histórico',
              style: TextStyle(
                color: _text(dark),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suas imagens geradas aparecerão aqui.',
              style: TextStyle(color: _sub(dark)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridFor(BuildContext context, String uid, bool dark) {
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
              style: TextStyle(color: _text(dark)),
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
              style: TextStyle(color: _sub(dark)),
            ),
          );
        }
        return LayoutBuilder(
          builder: (_, c) {
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
                final d = docs[i].data();
                final src = (d['downloadUrl'] ?? d['src'] ?? '') as String;
                final prompt =
                    (d['prompt'] ?? d['promptUsado'] ?? '') as String;
                final model = (d['model'] ?? '') as String;
                return _card(context, dark, src, prompt, model, i);
              },
            );
          },
        );
      },
    );
  }

  Widget _card(
    BuildContext context,
    bool dark,
    String src,
    String prompt,
    String model,
    int index,
  ) {
    final layer = _layer(dark);
    final border = _border(dark);
    return InkWell(
      onTap: () => _viewer(context, dark, src, prompt, model),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: layer,
          border: Border.all(color: border),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            _viewer(context, dark, src, prompt, model),
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () async {
                          await downloadImage(
                            src,
                            filename: 'eduimage_$index.png',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Imagem salva.')),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.download_rounded,
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

  void _viewer(
    BuildContext context,
    bool dark,
    String src,
    String prompt,
    String model,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (_, c) {
              final isWide = c.maxWidth >= 900;
              return Container(
                decoration: BoxDecoration(
                  color: _layer(dark),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border(dark)),
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
                            child: _details(
                              dark,
                              prompt,
                              model,
                              src,
                              dialogCtx,
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
                          _details(dark, prompt, model, src, dialogCtx),
                        ],
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _details(
    bool dark,
    String prompt,
    String model,
    String src,
    BuildContext dialogCtx,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xff0F1220) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border(dark)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entradas',
            style: TextStyle(
              color: _text(dark),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (model.isNotEmpty) ...[
            Text(
              'Modelo',
              style: TextStyle(color: _sub(dark), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(model, style: TextStyle(color: _text(dark))),
            const SizedBox(height: 10),
          ],
          Text(
            'Prompt utilizado',
            style: TextStyle(color: _sub(dark), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            prompt.isEmpty ? 'Indisponível' : prompt,
            style: TextStyle(color: _text(dark), height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonal(
                onPressed: () => downloadImage(src, filename: 'eduimage.png'),
                child: const Text('Baixar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
