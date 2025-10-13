import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/core/configs/assets/vectors.dart';
import 'package:app/core/configs/theme/colors.dart';
import 'package:app/features/auth/auth_service.dart';
import 'package:app/features/splash/splash_page.dart';
import 'package:app/features/history/history_service.dart';
import 'package:app/features/history/history_page.dart';
import 'package:app/features/home/options.dart';
import 'package:app/features/home/widgets/controls_card.dart';
import 'package:app/features/home/widgets/prompt_card.dart';
import 'package:app/features/home/widgets/remote_history_grid.dart';
import 'package:app/features/admin/admin_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isAdmin = false;

  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;

  String selectedTemaLabel = temaOptions.first['label'] as String;
  String selectedSubareaLabel = subareaLabelsForTemaValue(
    temaOptions.first['value'] as String,
  ).first;
  String selectedEstiloLabel = estiloOptions.first['label'] as String;
  String selectedAspect = aspectos.first;
  bool modoDidatico = true;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _resolveIsAdmin();
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      _ensureUserDoc(u);
    }
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, .08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _ensureUserDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();
    final now = FieldValue.serverTimestamp();
    final search = _buildSearch(user);
    if (!snap.exists) {
      await ref.set({
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'createdAt': now,
        'disabled': false,
        'role': 'user',
        'search': search,
      });
      return;
    }
    await ref.update({
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'search': search,
    });
  }

  List<String> _buildSearch(User u) {
    final e = (u.email ?? '').toLowerCase();
    final n = (u.displayName ?? '').toLowerCase();
    final tokens = <String>{};
    void addTokens(String s) {
      final parts = s.split(RegExp(r'[\s@._-]+')).where((p) => p.isNotEmpty);
      for (final p in parts) {
        for (int i = 1; i <= p.length; i++) {
          tokens.add(p.substring(0, i));
        }
      }
    }

    addTokens(e);
    addTokens(n);
    return tokens.toList();
  }

  Future<void> _resolveIsAdmin() async {
    final u = authService.value.currentUser;
    if (u == null) return;
    bool admin = false;
    try {
      final token = await u.getIdTokenResult(true);
      final claims = token.claims ?? {};
      if (claims['admin'] == true) admin = true;
    } catch (_) {}
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .get();
      final data = snap.data();
      if (data != null) {
        if (data['role'] == 'admin') admin = true;
        final roles = data['roles'];
        if (roles is Map && roles['admin'] == true) admin = true;
      }
    } catch (_) {}
    if (mounted) setState(() => _isAdmin = admin);
  }

  Future<void> _generateImage() async {
    final base = _promptController.text.trim();
    if (base.isEmpty) return;
    final texto = modoDidatico
        ? '$base. Use rótulos claros, alto contraste, sem marcas, fundo neutro, texto legível, setas para indicar relações e grandezas quando necessário.'
        : base;
    setState(() => _isGenerating = true);
    try {
      final temaValue = temaValueFromLabel(selectedTemaLabel);
      final subValue = subareaValueFromLabel(temaValue, selectedSubareaLabel);
      final estiloValue = estiloValueFromLabel(selectedEstiloLabel);
      final functions = FirebaseFunctions.instanceFor(
        region: 'southamerica-east1',
      );
      final callable = functions.httpsCallable('generateImage');
      final result = await callable.call({
        'tema': temaValue,
        'subarea': subValue,
        'estilo': estiloValue,
        'detalhes': texto,
        'aspectRatio': selectedAspect,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final dataUrl = data['imageDataUrl'] as String?;
      final model = data['model'] as String?;
      final prompt = data['promptUsado'] as String?;
      if (dataUrl == null || dataUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível gerar a imagem.')),
          );
        }
        return;
      }
      final uid = authService.value.currentUser?.uid;
      if (uid != null) {
        await HistoryService().saveGenerated(
          uid: uid,
          src: dataUrl,
          model: model,
          prompt: prompt ?? base,
          aspectRatio: selectedAspect,
          temaSelecionado: selectedTemaLabel,
          subareaSelecionada: selectedSubareaLabel,
          temaResolvido: temaValue,
          subareaResolvida: subValue,
        );
      }
      _promptController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<int> _countImages() async {
    final uid = authService.value.currentUser?.uid;
    if (uid == null) return 0;
    final agg = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('images')
        .count()
        .get();
    return agg.count ?? 0;
  }

  Future<void> _changeName() async {
    final currentName = authService.value.currentUser?.displayName ?? '';
    final ctrl = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Alterar Nome',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Digite seu novo nome',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (newName != null && newName != currentName) {
      try {
        await authService.value.currentUser?.updateDisplayName(newName);
        await authService.value.currentUser?.reload();
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nome alterado com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao alterar nome: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.home_rounded),
        label: 'Criar',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_rounded),
        label: 'Minha Conta',
      ),
      if (_isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.shield_moon_outlined),
          label: 'Admin',
        ),
    ];
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 76,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SvgPicture.asset(Vectors.logo, height: 52, width: 52),
        ),
      ),
      body: _currentIndex == 0
          ? _homeScreen()
          : _currentIndex == 1
          ? _accountScreen()
          : const AdminPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          if (i == 0) {
            _anim.reset();
            _anim.forward();
          }
        },
        destinations: destinations,
      ),
    );
  }

  Widget _homeScreen() {
    final uid = authService.value.currentUser?.uid;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFF7FB), Color(0xFFF8F6F4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top + 110),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crie sua imagem educativa',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Defina o tema, a subárea e o estilo. Depois descreva a imagem.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ControlsCard(
                          selectedTemaLabel: selectedTemaLabel,
                          selectedSubareaLabel: selectedSubareaLabel,
                          selectedEstiloLabel: selectedEstiloLabel,
                          selectedAspect: selectedAspect,
                          modoDidatico: modoDidatico,
                          onTemaChanged: (v) {
                            setState(() {
                              selectedTemaLabel = v;
                              selectedSubareaLabel = subareaLabelsForTemaValue(
                                temaValueFromLabel(selectedTemaLabel),
                              ).first;
                            });
                          },
                          onSubareaChanged: (v) =>
                              setState(() => selectedSubareaLabel = v),
                          onEstiloChanged: (v) =>
                              setState(() => selectedEstiloLabel = v),
                          onAspectChanged: (v) =>
                              setState(() => selectedAspect = v),
                          onModoDidaticoChanged: (v) =>
                              setState(() => modoDidatico = v),
                        ),
                        const SizedBox(height: 16),
                        PromptCard(
                          controller: _promptController,
                          onGenerate: _isGenerating ? () {} : _generateImage,
                          isGenerating: _isGenerating,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Histórico',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff383838),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: uid == null
                      ? const SizedBox.shrink()
                      : RemoteHistoryGrid(key: ValueKey(uid), uid: uid),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFF7FB), Color(0xFFF8F6F4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<int>(
            future: _countImages(),
            builder: (context, snap) {
              final total = snap.data ?? 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.blue,
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    authService.value.currentUser?.displayName ?? 'Usuário',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    authService.value.currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 22),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.edit, color: AppColors.blue),
                              title: const Text('Alterar nome'),
                              onTap: _changeName,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.verified_outlined),
                              title: const Text('Verificar e-mail'),
                              subtitle: const Text(
                                'Enviar link de verificação',
                              ),
                              onTap: () async {
                                try {
                                  await authService.value
                                      .sendEmailVerification();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'E-mail de verificação enviado.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.lock_reset),
                              title: const Text('Redefinir senha'),
                              subtitle: const Text(
                                'Enviar e-mail de redefinição',
                              ),
                              onTap: () async {
                                final email =
                                    authService.value.currentUser?.email;
                                if (email == null || email.isEmpty) return;
                                try {
                                  await authService.value.sendPasswordReset(
                                    email,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'E-mail de redefinição enviado.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.photo_library_outlined),
                              title: const Text('Minhas imagens'),
                              subtitle: Text('Total: $total'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HistoryPage(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(
                                Icons.logout,
                                color: Colors.red,
                              ),
                              title: const Text('Sair'),
                              onTap: () async {
                                await authService.value.signOut();
                                if (!mounted) return;
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const SplashPage(),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
