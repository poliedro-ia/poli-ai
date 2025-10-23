import 'dart:convert';
import 'package:app/core/configs/theme/theme_controller.dart';
import 'package:app/features/auth/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/core/configs/assets/images.dart';
import 'package:app/core/utils/media_utils.dart';
import 'package:app/features/history/history_page.dart';
import 'package:app/features/admin/admin_page.dart';

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
  String? _preview;
  int _currentIndex = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.idTokenChanges().listen((u) async {
      if (!mounted) return;
      if (u == null) {
        setState(() => _isAdmin = false);
        return;
      }
      final tok = await u.getIdTokenResult(true);
      final adm = (tok.claims?['admin'] as bool?) ?? false;
      setState(() => _isAdmin = adm);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _prompt.dispose();
    super.dispose();
  }

  Color _bg(bool d) => d ? const Color(0xff0B0E19) : const Color(0xffF7F8FA);
  Color _layer(bool d) => d ? const Color(0xff121528) : Colors.white;
  Color _border(bool d) =>
      d ? const Color(0xff1E2233) : const Color(0xffE7EAF0);
  Color _text(bool d) => d ? Colors.white : const Color(0xff0B1220);
  Color _subText(bool d) =>
      d ? const Color(0xff97A0B5) : const Color(0xff5A6477);
  Color _fieldBg(bool d) => d ? const Color(0xff0F1220) : Colors.white;
  Color _fieldBorder(bool d) =>
      d ? const Color(0xff23263A) : const Color(0xffD8DEE9);
  Color get _cta => const Color(0xff2563EB);
  Color _bar(bool d) => d ? const Color(0xff101425) : Colors.white;

  List<String> _subareasFor(String tema) {
    if (tema == 'Física') {
      return ['Eletricidade', 'Mecânica', 'Óptica', 'Termodinâmica'];
    } else {
      return ['Ligações', 'Reações', 'Estrutura', 'Estequiometria'];
    }
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
      setState(() => _preview = dataUrl);

      final b64 = dataUrl.split(',').last;
      base64Decode(b64);
      final now = DateTime.now();
      final ts = now.millisecondsSinceEpoch.toString();
      final path =
          'images/${user.uid}/${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/$ts.png';

      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('images');
      await ref.add({
        'downloadUrl': dataUrl,
        'src': dataUrl,
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  PreferredSizeWidget _appBar(bool dark) {
    return AppBar(
      backgroundColor: _bar(dark),
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
            dark ? Images.whiteLogo : Images.logo,
            height: kIsWeb ? 100 : 82,
            width: kIsWeb ? 100 : 82,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: kIsWeb ? 10 : 6),
          child: IconButton(
            tooltip: dark ? 'Tema claro' : 'Tema escuro',
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
        Padding(
          padding: EdgeInsets.only(right: kIsWeb ? 12 : 8),
          child: FilledButton.tonal(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: dark
                  ? const Color(0xff1E2A4A)
                  : const Color(0xffE9EEF9),
              foregroundColor: _text(dark),
              padding: EdgeInsets.symmetric(
                horizontal: kIsWeb ? 22 : 14,
                vertical: kIsWeb ? 12 : 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Histórico'),
          ),
        ),
        if (kIsWeb)
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (_, snap) {
              final logged = snap.data != null;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton(
                  onPressed: () {
                    if (logged) {
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
                    backgroundColor: _cta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(logged ? 'Minha Conta' : 'Login'),
                ),
              );
            },
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border(dark).withOpacity(0.7)),
      ),
    );
  }

  Widget _panels(bool isWide, bool dark) {
    final horizontalGap = isWide ? 32.0 : 12.0;
    final blockPad = kIsWeb ? 28.0 : 20.0;

    final leftPanel = Container(
      decoration: BoxDecoration(
        color: _layer(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(dark)),
      ),
      padding: EdgeInsets.all(blockPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gerador de Imagens',
            style: TextStyle(
              color: _text(dark),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: kIsWeb ? 12 : 8),
          Text(
            'Defina as opções e descreva sua imagem.',
            style: TextStyle(color: _subText(dark)),
          ),
          SizedBox(height: kIsWeb ? 20 : 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _tema,
                  items: const [
                    DropdownMenuItem(value: 'Física', child: Text('Física')),
                    DropdownMenuItem(value: 'Química', child: Text('Química')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    final subs = _subareasFor(v);
                    setState(() {
                      _tema = v;
                      if (!subs.contains(_sub)) _sub = subs.first;
                    });
                  },
                  decoration: _decSelect('Tema', dark),
                  dropdownColor: _fieldBg(dark),
                  style: TextStyle(color: _text(dark)),
                ),
              ),
              SizedBox(width: horizontalGap),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _sub,
                  items: _subareasFor(_tema)
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _sub = v!),
                  decoration: _decSelect('Subárea', dark),
                  dropdownColor: _fieldBg(dark),
                  style: TextStyle(color: _text(dark)),
                ),
              ),
            ],
          ),
          SizedBox(height: kIsWeb ? 16 : 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _estilo,
                  items: const [
                    DropdownMenuItem(
                      value: 'Vetorial',
                      child: Text('Vetorial'),
                    ),
                    DropdownMenuItem(
                      value: 'Realista',
                      child: Text('Realista'),
                    ),
                    DropdownMenuItem(value: 'Desenho', child: Text('Desenho')),
                  ],
                  onChanged: (v) => setState(() => _estilo = v!),
                  decoration: _decSelect('Estilo', dark),
                  dropdownColor: _fieldBg(dark),
                  style: TextStyle(color: _text(dark)),
                ),
              ),
              SizedBox(width: horizontalGap),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _aspect,
                  items: const [
                    DropdownMenuItem(value: '1:1', child: Text('1:1')),
                    DropdownMenuItem(value: '4:3', child: Text('4:3')),
                    DropdownMenuItem(value: '16:9', child: Text('16:9')),
                  ],
                  onChanged: (v) => setState(() => _aspect = v!),
                  decoration: _decSelect('Proporção', dark),
                  dropdownColor: _fieldBg(dark),
                  style: TextStyle(color: _text(dark)),
                ),
              ),
            ],
          ),
          SizedBox(height: kIsWeb ? 16 : 12),
          Row(
            children: [
              Switch(
                value: _didatico,
                onChanged: (v) => setState(() => _didatico = v),
              ),
              const SizedBox(width: 8),
              Text(
                'Modo Didático',
                style: TextStyle(
                  color: _text(dark),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: kIsWeb ? 16 : 12),
          TextFormField(
            controller: _prompt,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            cursorColor: _cta,
            style: TextStyle(color: _text(dark)),
            decoration: _decInput(
              label: 'Descreva sua imagem',
              hint: 'Ex: Diagrama de ligação covalente H–H com rótulos claros',
              dark: dark,
            ),
            enableSuggestions: true,
            autocorrect: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          SizedBox(height: kIsWeb ? 22 : 18),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _prompt,
            builder: (_, v, __) {
              final can = v.text.trim().isNotEmpty && !_loading;
              final fg = dark
                  ? (can ? Colors.white : const Color(0xFF2B3347))
                  : null;
              return SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: can ? _generate : null,
                  icon: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: Text(_loading ? 'Gerando...' : 'Gerar Imagem'),
                  style: FilledButton.styleFrom(
                    foregroundColor: fg,
                    backgroundColor: _cta,
                    disabledBackgroundColor: dark
                        ? const Color(0xff1B2A52)
                        : const Color(0xffC8D7FE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(vertical: kIsWeb ? 20 : 18),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );

    final rightPanel = Container(
      decoration: BoxDecoration(
        color: _layer(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(dark)),
      ),
      padding: EdgeInsets.all(blockPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resultado',
            style: TextStyle(
              color: _text(dark),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: kIsWeb ? 12 : 8),
          Text(
            'Sua imagem gerada aparecerá aqui',
            style: TextStyle(color: _subText(dark)),
          ),
          SizedBox(height: kIsWeb ? 16 : 12),
          _preview == null
              ? Container(
                  height: kIsWeb ? 320 : 260,
                  decoration: BoxDecoration(
                    color: _fieldBg(dark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _fieldBorder(dark)),
                  ),
                  child: Center(
                    child: Text(
                      'Sem imagem ainda',
                      style: TextStyle(color: _subText(dark)),
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: _aspect == '1:1'
                        ? 1
                        : (_aspect == '4:3' ? 4 / 3 : 16 / 9),
                    child: Image.network(_preview!, fit: BoxFit.cover),
                  ),
                ),
          SizedBox(height: kIsWeb ? 20 : 16),
          Row(
            children: [
              FilledButton.tonal(
                onPressed: _preview == null
                    ? null
                    : () =>
                          _zoom(context, ThemeController.instance.isDark.value),
                style: FilledButton.styleFrom(
                  backgroundColor: dark
                      ? const Color(0xff1F2937)
                      : const Color(0xffE9EEF9),
                  foregroundColor: _text(dark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: kIsWeb ? 18 : 16,
                    vertical: kIsWeb ? 16 : 14,
                  ),
                ),
                child: const Text('Ampliar'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _preview == null
                    ? null
                    : () => downloadImage(_preview!, filename: 'eduimage.png'),
                style: FilledButton.styleFrom(
                  backgroundColor: dark
                      ? const Color(0xff1F2937)
                      : const Color(0xffE9EEF9),
                  foregroundColor: _text(dark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: kIsWeb ? 18 : 16,
                    vertical: kIsWeb ? 16 : 14,
                  ),
                ),
                child: const Text('Baixar'),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: dark
                      ? const Color(0xff1F2937)
                      : const Color(0xffE9EEF9),
                  foregroundColor: _text(dark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: kIsWeb ? 18 : 16,
                    vertical: kIsWeb ? 16 : 14,
                  ),
                ),
                child: const Text('Ver histórico'),
              ),
            ],
          ),
        ],
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: leftPanel),
          const SizedBox(width: 32),
          Expanded(child: rightPanel),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [leftPanel, const SizedBox(height: 24), rightPanel],
      );
    }
  }

  void _zoom(BuildContext context, bool dark) {
    if (_preview == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: _layer(dark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border(dark)),
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
                    child: Image.network(_preview!, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.tonal(
                      onPressed: () =>
                          downloadImage(_preview!, filename: 'eduimage.png'),
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
        );
      },
    );
  }

  Widget _createBody(bool dark) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 960;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final heroTopPad = kIsWeb ? 64.0 : 40.0;
    final heroSidePad = kIsWeb ? 32.0 : 28.0;
    final heroBottomPad = kIsWeb ? 40.0 : 36.0;
    final heroTitleSize = kIsWeb ? 56.0 : 36.0;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: EdgeInsets.only(bottom: bottomInset + 16),
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
                      Text(
                        'Onde Ideias Viram\nImagens Educacionais',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _text(dark),
                          fontSize: heroTitleSize,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gere ilustrações educativas com aparência profissional para Física e Química. Simples, rápido e preciso.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _subText(dark),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
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
                  child: _panels(isWide, dark),
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
                        style: TextStyle(color: _subText(dark)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Física • Química',
                        style: TextStyle(
                          color: dark
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

  InputDecoration _decSelect(String label, bool dark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _subText(dark)),
      filled: true,
      fillColor: _fieldBg(dark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _fieldBorder(dark)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _fieldBorder(dark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _cta, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  InputDecoration _decInput({
    required String label,
    required String hint,
    required bool dark,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: _subText(dark)),
      hintStyle: TextStyle(
        color: dark ? const Color(0xff9AA3B6) : const Color(0xff8A93A6),
      ),
      filled: true,
      fillColor: _fieldBg(dark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _fieldBorder(dark)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _fieldBorder(dark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _cta, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDark,
      builder: (_, dark, __) {
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
        return Scaffold(
          backgroundColor: _bg(dark),
          resizeToAvoidBottomInset: true,
          appBar: _appBar(dark),
          body: _currentIndex == 0
              ? _createBody(dark)
              : _currentIndex == 1
              ? _accountBody(dark)
              : AdminPage(darkInitial: dark),
          bottomNavigationBar: showBottomNav
              ? BottomNavigationBar(
                  currentIndex: _currentIndex.clamp(0, items.length - 1),
                  onTap: (i) => setState(() => _currentIndex = i),
                  backgroundColor: _layer(dark),
                  selectedItemColor: _cta,
                  unselectedItemColor: _subText(dark),
                  items: items,
                )
              : null,
        );
      },
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
    final u = FirebaseAuth.instance.currentUser;
    final email = u?.email;
    if (email == null || email.isEmpty) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email de redefinição enviado.')),
    );
  }

  Widget _accountBody(bool dark) {
    final isWeb = kIsWeb;
    final side = isWeb ? 32.0 : 20.0;
    final maxW = isWeb ? 900.0 : double.infinity;

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
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _cta,
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    FirebaseAuth.instance.currentUser?.displayName ?? 'Usuário',
                    style: TextStyle(
                      color: _text(dark),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? '',
                    style: TextStyle(color: _subText(dark), fontSize: 16),
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (_, c) {
                      final wide = c.maxWidth >= 720;
                      final cross = wide ? 2 : 1;
                      return GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cross,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: wide ? 3.8 : 3.2,
                        ),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _layer(dark),
                              border: Border.all(color: _border(dark)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: ListTile(
                              leading: Icon(Icons.image, color: _text(dark)),
                              title: Text(
                                'Ver histórico salvo',
                                style: TextStyle(
                                  color: _text(dark),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HistoryPage(),
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: _layer(dark),
                              border: Border.all(color: _border(dark)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: ListTile(
                              leading: Icon(
                                Icons.mark_email_unread_outlined,
                                color: _text(dark),
                              ),
                              title: Text(
                                'Enviar e-mail de verificação',
                                style: TextStyle(
                                  color: _text(dark),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: _sendVerification,
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: _layer(dark),
                              border: Border.all(color: _border(dark)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: ListTile(
                              leading: Icon(
                                Icons.lock_reset,
                                color: _text(dark),
                              ),
                              title: Text(
                                'Redefinir senha',
                                style: TextStyle(
                                  color: _text(dark),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: _sendReset,
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ),
                          if (_isAdmin)
                            Container(
                              decoration: BoxDecoration(
                                color: _layer(dark),
                                border: Border.all(color: _border(dark)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: ListTile(
                                leading: Icon(
                                  Icons.admin_panel_settings,
                                  color: _text(dark),
                                ),
                                title: Text(
                                  'Área do Administrador',
                                  style: TextStyle(
                                    color: _text(dark),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AdminPage(darkInitial: dark),
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: _layer(dark),
                              border: Border.all(color: _border(dark)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: ListTile(
                              leading: const Icon(
                                Icons.logout,
                                color: Colors.redAccent,
                              ),
                              title: Text(
                                'Sair',
                                style: TextStyle(
                                  color: _text(dark),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () async {
                                await FirebaseAuth.instance.signOut();
                                if (!mounted) return;
                                Navigator.of(context).pop();
                              },
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ),
                        ],
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
}
