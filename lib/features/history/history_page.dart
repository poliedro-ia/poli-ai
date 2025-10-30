import 'package:app/core/configs/assets/images.dart';
import 'package:app/core/utils/media_utils.dart';
import 'package:app/features/home/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:app/features/history/ui/history_ui.dart';
import 'package:app/features/history/widgets/history_card.dart';
import 'package:app/features/history/widgets/viewer_dialog.dart';
import 'package:app/core/motion/motion.dart';
import 'package:app/core/motion/route.dart';

class HistoryPage extends StatefulWidget {
  static const route = '/history';
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

  PreferredSizeWidget _appBar(HistoryPalette p) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: p.bg,
      foregroundColor: p.textMain,
      elevation: 0,
      toolbarHeight: 76,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: GestureDetector(
          onTap: () {
            Navigator.push(context, slideUpRoute(const HomePage()));
          },
          child: Entry(
            dy: -8,
            child: Image.asset(
              _dark ? Images.whiteLogo : Images.logo,
              height: 100,
              width: 100,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Entry(
            dy: -8,
            delay: const Duration(milliseconds: 120),
            child: FilledButton(
              onPressed: () {
                Navigator.push(context, slideUpRoute(const HomePage()));
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Voltar'),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: p.textSub.withOpacity(0.25)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    final p = HistoryPalette(_dark);
    return Motion(
      base: const Duration(milliseconds: 320),
      child: Scaffold(
        backgroundColor: p.bg,
        appBar: _appBar(p),
        body: Switcher(
          child: u == null ? _requireLogin(p) : _groupedGrid(p, u.uid),
        ),
      ),
    );
  }

  Widget _requireLogin(HistoryPalette p) {
    return Center(
      child: Entry(
        dy: 10,
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
      ),
    );
  }

  /// ---------- NOVO: grade agrupada por disciplina ----------
  Widget _groupedGrid(HistoryPalette p, String uid) {
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

        // Agrupa por disciplina / assunto
        final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        groups = {};
        for (final d in docs) {
          final m = d.data();
          final tema =
              (m['temaResolvido'] ??
                      m['temaSelecionado'] ??
                      m['tema'] ??
                      'Geral')
                  as String;
          final title = _titleCase(tema);
          groups.putIfAbsent(title, () => []).add(d);
        }

        final sortedKeys = groups.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          itemCount: sortedKeys.length,
          itemBuilder: (_, gi) {
            final key = sortedKeys[gi];
            final list = groups[key]!;
            return _Section(
              title: key,
              palette: p,
              child: LayoutBuilder(
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
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final doc = list[i];
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

                      return Entry(
                        delay: Duration(milliseconds: 40 + (i % cross) * 70),
                        dy: 10,
                        child: HistoryImageCard(
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
                            allDocs:
                                list, // navegação por setas dentro do grupo
                          ),
                          onDownload: () => downloadImage(
                            src,
                            filename:
                                'PoliAI_${DateTime.now().millisecondsSinceEpoch}',
                          ),
                          onDelete: () => _confirmDelete(id, storagePath, src),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
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
        filename: 'PoliAI_${DateTime.now().millisecondsSinceEpoch}',
      ),
      onDelete: () {
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
      builder: (_) => Entry(
        dy: 8,
        child: AlertDialog(
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

class _SectionStyle {
  final List<Color> gradient;
  final IconData icon;
  const _SectionStyle(this.gradient, this.icon);
}

_SectionStyle _sectionStyleFor(String title, HistoryPalette p) {
  final t = title.toLowerCase();

  if (t.contains('fís') || t.contains('fis')) {
    return _SectionStyle([
      const Color(0xFF7C3AED), // purple-600
      const Color(0xFF2563EB), // blue-600
    ], Icons.bolt_rounded);
  }
  if (t.contains('quím') || t.contains('quim')) {
    return _SectionStyle([
      const Color(0xFF14B8A6), // teal-500
      const Color(0xFF22C55E), // green-500
    ], Icons.science_rounded);
  }

  // Default “tech”
  return _SectionStyle([
    const Color(0xFF6366F1), // indigo-500
    const Color(0xFF06B6D4), // cyan-500
  ], Icons.grid_view_rounded);
}

class _Section extends StatefulWidget {
  final String title;
  final HistoryPalette palette;
  final Widget child;

  const _Section({
    required this.title,
    required this.palette,
    required this.child,
  });

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section>
    with SingleTickerProviderStateMixin {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final s = _sectionStyleFor(widget.title, p);

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: p.layer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(p.dark ? 0.35 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // HEADER
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _open = !_open),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    // Ícone em pill com gradiente
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: s.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(s.icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    // Título com tipografia “tech”
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: p.textMain,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Linha sutil decorativa (vibe “tecnológica”)
                          Container(
                            height: 3,
                            width: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: s.gradient
                                    .map((c) => c.withOpacity(.9))
                                    .toList(),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botão colapsar com glass
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.dark
                            ? const Color(0x22151827)
                            : const Color(0x22FFFFFF),
                        border: Border.all(color: p.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: AnimatedRotation(
                          turns: _open ? 0.0 : -0.25,
                          duration: const Duration(milliseconds: 220),
                          child: Icon(
                            Icons.expand_more_rounded,
                            color: p.textMain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // CONTEÚDO
            AnimatedCrossFade(
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeOutCubic,
              duration: const Duration(milliseconds: 260),
              crossFadeState: _open
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                child: widget.child,
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
