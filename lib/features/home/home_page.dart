import 'dart:convert';
import 'package:app/core/configs/assets/images.dart';
import 'package:app/core/configs/theme/theme_controller.dart';
import 'package:app/core/ui/anim/anim_utils.dart';
import 'package:app/core/utils/media_utils.dart';
import 'package:app/features/account/edit_name_dialog.dart';
import 'package:app/features/admin/admin_page.dart';
import 'package:app/features/auth/pages/login_page.dart';
import 'package:app/features/history/history_page.dart';
import 'package:app/features/home/ui/home_ui.dart';
import 'package:app/features/home/widgets/generator_panel.dart';
import 'package:app/features/home/widgets/result_panel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  final _scroll = ScrollController();
  final _genKey = GlobalKey();
  final _prompt = TextEditingController();

  String _tema = 'Física';
  String _sub = 'Eletricidade';
  String _estilo = 'Vetorial';
  String _aspect = '16:9';
  bool _didatico = true;
  bool _loading = false;
  String? _previewUrl;
  int _currentIndex = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.idTokenChanges().listen((u) async {
      if (!mounted) return;
      if (u == null) return setState(() => _isAdmin = false);
      final tok = await u.getIdTokenResult(true);
      setState(() => _isAdmin = (tok.claims?['admin'] as bool?) ?? false);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _prompt.dispose();
    super.dispose();
  }

  List<String> _subareasFor(String tema) {
    if (tema == 'Física') {
      return ['Eletricidade', 'Mecânica', 'Óptica', 'Termodinâmica'];
    }
    return ['Ligações', 'Reações', 'Estrutura', 'Estequiometria'];
  }

  Future<void> _generate() async {
    final detalhesBase = _prompt.text.trim();
    if (detalhesBase.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descreva sua imagem antes de gerar.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              Login(darkInitial: ThemeController.instance.isDark.value),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final texto = _didatico
          ? '$detalhesBase. Use rótulos claros, alto contraste, sem marcas, fundo neutro, texto legível, setas para indicar relações e grandezas quando necessário.'
          : detalhesBase;

      final callable = FirebaseFunctions.instanceFor(
        region: 'southamerica-east1',
      ).httpsCallable('generateImage');
      final result = await callable.call({
        'tema': _tema.toLowerCase(),
        'subarea': _sub.toLowerCase(),
        'estilo': _estilo.toLowerCase(),
        'detalhes': texto,
        'aspectRatio': _aspect,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final dataUrl = data['imageDataUrl'] as String?;
      if (dataUrl == null || dataUrl.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível gerar a imagem.')),
        );
        return;
      }

      final mime = dataUrl.substring(5, dataUrl.indexOf(';'));
      final ext = mime.split('/').last;
      final b64 = dataUrl.split(',').last;
      final bytes = base64Decode(b64);

      final now = DateTime.now();
      final ts = now.millisecondsSinceEpoch.toString();
      final path =
          'images/${user.uid}/${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/$ts.$ext';

      final ref = FirebaseStorage.instance.ref(path);
      await ref.putData(bytes, SettableMetadata(contentType: mime));
      final url = await ref.getDownloadURL();

      setState(() => _previewUrl = url);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('images')
          .add({
            'downloadUrl': url,
            'src': url,
            'storagePath': path,
            'model': data['model'] as String? ?? '',
            'prompt': data['promptUsado'] as String? ?? texto,
            'aspectRatio': _aspect,
            'temaSelecionado': _tema,
            'subareaSelecionada': _sub,
            'temaResolvido': _tema.toLowerCase(),
            'subareaResolvida': _sub.toLowerCase(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      _prompt.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  PreferredSizeWidget _appBar(HomePalette p) {
    final user = FirebaseAuth.instance.currentUser;
    return AppBar(
      backgroundColor: p.barBg,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: kIsWeb ? 76 : kToolbarHeight,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.only(left: kIsWeb ? 20 : 14),
        child: GestureDetector(
          onTap: () async {
            setState(() => _currentIndex = 0);
            await _scroll.animateTo(
              0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
            );
          },
          child: Image.asset(
            ThemeController.instance.isDark.value
                ? Images.whiteLogo
                : Images.logo,
            height: kIsWeb ? 100 : 82,
            width: kIsWeb ? 100 : 82,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: kIsWeb ? 10 : 6),
          child: IconButton(
            tooltip: ThemeController.instance.isDark.value
                ? 'Tema claro'
                : 'Tema escuro',
            onPressed: () => ThemeController.instance.toggle(),
            icon: Icon(
              ThemeController.instance.isDark.value
                  ? Icons.wb_sunny_outlined
                  : Icons.dark_mode_outlined,
              color: p.text,
              size: kIsWeb ? 24 : 22,
            ),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(10),
              backgroundColor: p.dark
                  ? const Color(0x221E2A4A)
                  : const Color(0x22E9EEF9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton(
            onPressed: () {
              if (user != null) {
                setState(() => _currentIndex = 1);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Login(
                      darkInitial: ThemeController.instance.isDark.value,
                    ),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: p.cta,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(user != null ? 'Minha Conta' : 'Login'),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: p.border.withOpacity(0.7)),
      ),
    );
  }

  Widget _bodyCreate(HomePalette p) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 960;

    final left = FadeSlide(
      delay: const Duration(milliseconds: 100),
      child: GeneratorPanel(
        p: p,
        tema: _tema,
        subarea: _sub,
        estilo: _estilo,
        aspect: _aspect,
        didatico: _didatico,
        temaOptions: const ['Física', 'Química'],
        subareaOptions: _subareasFor(_tema),
        estiloOptions: const ['Vetorial', 'Realista', 'Desenho'],
        aspectOptions: const ['1:1', '3:2', '4:3', '16:9', '9:16'],
        onTema: (v) {
          final subs = _subareasFor(v);
          setState(() {
            _tema = v;
            if (!subs.contains(_sub)) _sub = subs.first;
          });
        },
        onSubarea: (v) => setState(() => _sub = v),
        onEstilo: (v) => setState(() => _estilo = v),
        onAspect: (v) => setState(() => _aspect = v),
        onDidatico: (v) => setState(() => _didatico = v),
        prompt: _prompt,
        loading: _loading,
        onGenerate: _generate,
      ),
    );

    final right = FadeSlide(
      delay: const Duration(milliseconds: 160),
      child: ResultPanel(
        p: p,
        previewDataUrlOrUrl: _previewUrl,
        aspect: _aspect,
        onZoom: () => _zoom(context, p),
        canDownload: _previewUrl != null,
      ),
    );

    final heroTopPad = kIsWeb ? 64.0 : 40.0;
    final heroSidePad = kIsWeb ? 32.0 : 28.0;
    final heroBottomPad = kIsWeb ? 40.0 : 36.0;
    final heroTitleSize = kIsWeb ? 56.0 : 36.0;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                heroSidePad,
                heroTopPad,
                heroSidePad,
                heroBottomPad,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      FadeSlide(
                        delay: const Duration(milliseconds: 80),
                        child: Text(
                          'Onde Ideias Viram\nImagens Educacionais',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: p.text,
                            fontSize: heroTitleSize,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeSlide(
                        delay: const Duration(milliseconds: 160),
                        beginOffset: const Offset(0, .04),
                        child: Text(
                          'Gere ilustrações educativas com aparência profissional para Física e Química. Simples, rápido e preciso.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: p.subText,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              key: _genKey,
              padding: EdgeInsets.fromLTRB(
                heroSidePad,
                0,
                heroSidePad,
                kIsWeb ? 64 : 48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: left),
                            const SizedBox(width: 32),
                            Expanded(child: right),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [left, const SizedBox(height: 24), right],
                        ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                heroSidePad,
                16,
                heroSidePad,
                kIsWeb ? 36 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      Text(
                        'EduImage • Ferramenta para criação de imagens educacionais',
                        style: TextStyle(color: p.subText),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Física • Química',
                        style: TextStyle(
                          color: p.dark
                              ? const Color(0xff6F7891)
                              : const Color(0xff6A768F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bodyAccount(HomePalette p) {
    final u = FirebaseAuth.instance.currentUser;
    if (!kIsWeb && u == null) {
      final side = 24.0;
      return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: side, vertical: 32),
              child: Container(
                decoration: BoxDecoration(
                  color: p.layer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.border),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Icon(Icons.lock_outline, size: 48, color: p.subText),
                    const SizedBox(height: 12),
                    Text(
                      'Faça login para continuar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: p.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acesse sua conta para ver seu perfil e histórico.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.subText),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Login(darkInitial: p.dark),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: p.cta,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Fazer login'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final side = kIsWeb ? 32.0 : 20.0;
    final maxW = kIsWeb ? 900.0 : double.infinity;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: side, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  ScaleIn(
                    delay: const Duration(milliseconds: 60),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: p.cta,
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlide(
                    delay: const Duration(milliseconds: 120),
                    child: Text(
                      u?.displayName ?? 'Usuário',
                      style: TextStyle(
                        color: p.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeSlide(
                    delay: const Duration(milliseconds: 160),
                    child: Text(
                      u?.email ?? '',
                      style: TextStyle(color: p.subText, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (_, c) {
                      final wide = c.maxWidth >= 720;
                      final cross = wide ? 2 : 1;
                      final items = [
                        ScaleOnTap(
                          child: _accountItem(
                            p,
                            Icons.image,
                            'Ver histórico salvo',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HistoryPage(darkInitial: p.dark),
                                  settings: const RouteSettings(
                                    name: '/history',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        ScaleOnTap(
                          child: _accountItem(
                            p,
                            Icons.edit,
                            'Editar nome de usuário',
                            () async {
                              final initial = u?.displayName ?? '';
                              final newName = await showDialog<String>(
                                context: context,
                                builder: (_) =>
                                    EditNameDialog(initialName: initial),
                              );
                              if (newName != null &&
                                  newName.trim().isNotEmpty &&
                                  FirebaseAuth.instance.currentUser != null) {
                                await FirebaseAuth.instance.currentUser!
                                    .updateDisplayName(newName.trim());
                                await FirebaseAuth.instance.currentUser!
                                    .reload();
                                if (!mounted) return;
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nome atualizado.'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        ScaleOnTap(
                          child: _accountItem(
                            p,
                            Icons.mark_email_unread_outlined,
                            'Enviar e-mail de verificação',
                            _sendVerification,
                          ),
                        ),
                        ScaleOnTap(
                          child: _accountItem(
                            p,
                            Icons.lock_reset,
                            'Redefinir senha',
                            _sendReset,
                          ),
                        ),
                        if (_isAdmin)
                          ScaleOnTap(
                            child: _accountItem(
                              p,
                              Icons.admin_panel_settings,
                              'Área do Administrador',
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminPage(darkInitial: p.dark),
                                ),
                              ),
                            ),
                          ),
                        ScaleOnTap(
                          child: _accountItem(
                            p,
                            Icons.logout,
                            'Sair',
                            () async {
                              await FirebaseAuth.instance.signOut();
                              if (!mounted) return;
                              setState(() => _currentIndex = 0);
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const HomePage(),
                                ),
                                (route) => false,
                              );
                            },
                            color: Colors.redAccent,
                          ),
                        ),
                      ];
                      return GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cross,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: wide ? 3.8 : 3.2,
                        ),
                        children: List.generate(
                          items.length,
                          (i) => FadeSlide(
                            delay: Duration(milliseconds: 60 * i),
                            child: items[i],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountItem(
    HomePalette p,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: p.layer,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: ListTile(
        leading: Icon(icon, color: color ?? p.text),
        title: Text(
          label,
          style: TextStyle(color: p.text, fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Future<void> _sendVerification() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    await u.sendEmailVerification();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Verificação enviada.')));
  }

  Future<void> _sendReset() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email de redefinição enviado.')),
    );
  }

  void _zoom(BuildContext context, HomePalette p) {
    final src = _previewUrl;
    if (src == null) return;

    if (kIsWeb) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.75),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: p.layer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.network(src, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => downloadImage(
                        src,
                        filename:
                            'PoliAI_${DateTime.now().millisecondsSinceEpoch}',
                      ),
                      child: const Text('Baixar'),
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
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) {
        final size = MediaQuery.of(context).size;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: size.height - 24,
                maxWidth: size.width - 24,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: p.layer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.border),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4,
                          child: Center(child: Image.network(src)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () => downloadImage(
                              src,
                              filename:
                                  'PoliAI_${DateTime.now().millisecondsSinceEpoch}',
                            ),
                            child: const Text('Baixar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fechar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDark,
      builder: (_, dark, __) {
        final p = HomePalette(dark);
        final showBottomNav = !kIsWeb;

        final items = <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Criar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Minha Conta',
          ),
          if (_isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ];
        final isAdminTabMobile = !kIsWeb && _isAdmin && _currentIndex == 2;

        return Scaffold(
          backgroundColor: p.bg,
          resizeToAvoidBottomInset: true,
          appBar: isAdminTabMobile ? null : _appBar(p),
          body: _currentIndex == 0
              ? _bodyCreate(p)
              : _currentIndex == 1
              ? _bodyAccount(p)
              : AdminPage(darkInitial: dark),
          bottomNavigationBar: showBottomNav
              ? BottomNavigationBar(
                  currentIndex: _currentIndex.clamp(0, items.length - 1),
                  onTap: (i) {
                    if (!kIsWeb &&
                        i == 1 &&
                        FirebaseAuth.instance.currentUser == null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Login(darkInitial: dark),
                        ),
                      );
                      return;
                    }
                    setState(() => _currentIndex = i);
                  },
                  backgroundColor: p.layer,
                  selectedItemColor: p.cta,
                  unselectedItemColor: p.subText,
                  items: items,
                )
              : null,
        );
      },
    );
  }
}
