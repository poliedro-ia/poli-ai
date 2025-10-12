import 'dart:convert';
import 'package:app/core/configs/theme/colors.dart';
import 'package:app/core/configs/assets/vectors.dart';
import 'package:app/features/auth/auth_service.dart';
import 'package:app/features/splash/splash_page.dart';
import 'package:app/features/home/options.dart';
import 'package:app/features/home/image_viewer_page.dart';
import 'package:app/core/utils/media_utils.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/features/history/history_service.dart';
import 'package:app/features/history/history_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/features/admin/admin_page.dart';
import 'package:app/features/admin/admin_service.dart';

class ImageItem {
  final String src;
  final String? model;
  final String? prompt;
  ImageItem({required this.src, this.model, this.prompt});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isAdmin = false;

  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isGenerating = false;
  final List<ImageItem> _images = [];

  String selectedTemaLabel = temaOptions.first['label'] as String;
  String selectedSubareaLabel = subareaLabelsForTemaValue(
    temaOptions.first['value'] as String,
  ).first;
  String selectedEstiloLabel = estiloOptions.first['label'] as String;
  String selectedAspect = aspectos.first;
  bool modoDidatico = true;

  Future<void> _checkAdmin() async {
    final u = authService.value.currentUser;
    if (u == null) return;
    final t = await u.getIdTokenResult(true);
    final claims = t.claims ?? {};
    final isAdmin = claims['admin'] == true;
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
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
      setState(() {
        _images.insert(
          0,
          ImageItem(src: dataUrl, model: model, prompt: prompt),
        );
        _promptController.clear();
      });
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

  Future<void> _changeName() async {
    final currentName = authService.value.currentUser?.displayName ?? '';
    _nameController.text = currentName;
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Alterar Nome',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: _nameController,
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
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, _nameController.text.trim());
              }
            },
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

  InputDecoration _fieldDeco(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E6C86), width: 1.6),
      ),
    );
  }

  Widget _sectionTitle(String title, {Widget? action}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _controles() {
    final temaValue = temaValueFromLabel(selectedTemaLabel);
    final subLabels = subareaLabelsForTemaValue(temaValue);
    if (!subLabels.contains(selectedSubareaLabel)) {
      selectedSubareaLabel = subLabels.first;
    }
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedTemaLabel,
                    items: temaOptions
                        .map(
                          (e) => DropdownMenuItem(
                            value: e['label'] as String,
                            child: Text(
                              e['label'] as String,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      selectedTemaLabel = v!;
                      selectedSubareaLabel = subareaLabelsForTemaValue(
                        temaValueFromLabel(selectedTemaLabel),
                      ).first;
                    }),
                    decoration: _fieldDeco('Tema'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedSubareaLabel,
                    items: subLabels
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedSubareaLabel = v!),
                    decoration: _fieldDeco('Subárea'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedEstiloLabel,
                    items: estiloOptions
                        .map(
                          (e) => DropdownMenuItem(
                            value: e['label'] as String,
                            child: Text(
                              e['label'] as String,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedEstiloLabel = v!),
                    decoration: _fieldDeco('Estilo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedAspect,
                    items: aspectos
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedAspect = v!),
                    decoration: _fieldDeco('Proporção'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Switch(
                    value: modoDidatico,
                    onChanged: (v) => setState(() => modoDidatico = v),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Modo Didático',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promptCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _promptController,
          minLines: 4,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: 'Descreva sua imagem...',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF1E6C86),
                width: 1.6,
              ),
            ),
            helperText:
                'Ex: Diagrama de ligação covalente H–H com pares de elétrons e rótulos',
            helperMaxLines: 2,
          ),
          enableSuggestions: true,
          autocorrect: true,
          textCapitalization: TextCapitalization.sentences,
        ),
      ),
    );
  }

  Widget _generateBar() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isGenerating ? null : _generateImage,
        icon: Icon(_isGenerating ? Icons.hourglass_empty : Icons.auto_awesome),
        label: Text(_isGenerating ? 'Gerando...' : 'Gerar Imagem'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _localHistoryGrid() {
    if (_images.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Nenhuma imagem gerada ainda',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        int cross = 1;
        if (w >= 1100)
          cross = 3;
        else if (w >= 700)
          cross = 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 16 / 10,
          ),
          itemCount: _images.length,
          itemBuilder: (context, index) {
            final item = _images[index];
            final src = item.src;
            final isDataUrl = src.startsWith('data:image/');
            final tag = 'img_$index';
            final preview = isDataUrl
                ? Image.memory(
                    base64Decode(src.split(',').last),
                    fit: BoxFit.cover,
                  )
                : Image.network(src, fit: BoxFit.cover);
            return Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(tag: tag, child: preview),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              await downloadImage(
                                src,
                                filename: 'eduimage_$index',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Imagem salva.'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.download,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await shareImage(
                                src,
                                filename: 'eduimage_$index',
                              );
                            },
                            icon: const Icon(Icons.share, color: Colors.white),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ImageViewerPage(
                                    src: src,
                                    tag: tag,
                                    model: item.model,
                                    prompt: item.prompt,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
    return (agg.count ?? 0);
  }

  Widget _accountScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<int>(
          future: _countImages(),
          builder: (context, snap) {
            final total = snap.data ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.blue,
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  authService.value.currentUser?.displayName ?? 'Usuário',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  authService.value.currentUser?.email ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                        subtitle: const Text('Enviar link de verificação'),
                        onTap: () async {
                          try {
                            await authService.value.sendEmailVerification();
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
                        subtitle: const Text('Enviar e-mail de redefinição'),
                        onTap: () async {
                          final email = authService.value.currentUser?.email;
                          if (email == null || email.isEmpty) return;
                          try {
                            await authService.value.sendPasswordReset(email);
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
                      FutureBuilder<bool>(
                        future: (() async {
                          final u = authService.value.currentUser;
                          if (u == null) return false;
                          final t = await u.getIdTokenResult(true);
                          return (t.claims?['admin'] == true);
                        })(),
                        builder: (context, snapAdmin) {
                          final isAdmin = snapAdmin.data == true;
                          if (isAdmin) return const SizedBox.shrink();
                          return ListTile(
                            leading: const Icon(Icons.security),
                            title: const Text('Tornar-me Admin'),
                            subtitle: const Text(
                              'Apenas durante desenvolvimento',
                            ),
                            onTap: () async {
                              try {
                                await AdminService().selfPromote();
                                await _checkAdmin();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Você agora é admin.'),
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
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
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
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinations = <NavigationDestination>[
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
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];
    return Scaffold(
      body: _currentIndex == 0
          ? _homeScreen()
          : _currentIndex == 1
          ? _accountScreen()
          : const AdminPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: destinations,
      ),
    );
  }

  Widget _homeScreen() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: SvgPicture.asset(Vectors.logo, height: 44, width: 44),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crie sua imagem educativa',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Defina o tema, a subárea e o estilo. Depois descreva a imagem.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _controles(),
                  const SizedBox(height: 16),
                  _promptCard(),
                  const SizedBox(height: 16),
                  _generateBar(),
                  const SizedBox(height: 24),
                  _sectionTitle(
                    'Histórico',
                    action: FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.cloud),
                      label: const Text('Ver histórico salvo'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _localHistoryGrid(),
            ),
          ),
        ],
      ),
    );
  }
}
