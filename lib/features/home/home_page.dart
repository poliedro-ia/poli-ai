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
import 'package:flutter/foundation.dart';

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
    } catch (e) {
      debugPrint('Erro ao gerar imagem: $e');
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.blue),
            ),
          ),
          TextButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, _nameController.text.trim());
              }
            },
            style: TextButton.styleFrom(backgroundColor: AppColors.blue),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
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

  Widget _controles() {
    final temaValue = temaValueFromLabel(selectedTemaLabel);
    final subLabels = subareaLabelsForTemaValue(temaValue);
    if (!subLabels.contains(selectedSubareaLabel)) {
      selectedSubareaLabel = subLabels.first;
    }
    return Column(
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
                decoration: dropDeco('Tema'),
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
                decoration: dropDeco('Subárea'),
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
                decoration: dropDeco('Estilo'),
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
                decoration: dropDeco('Proporção'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
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
      ],
    );
  }

  Widget _homeScreen() {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: SizedBox(
            height: kToolbarHeight,
            child: Center(
              child: SvgPicture.asset(Vectors.logo, height: 40, width: 40),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height:
                    kToolbarHeight + MediaQuery.of(context).padding.top + 20,
              ),
              const Text(
                'Crie sua imagem educativa',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Defina o tema, a subárea e o estilo. Depois descreva a imagem.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _controles(),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _promptController,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText:
                        'Ex: Diagrama de ligação covalente H–H com pares de elétrons e rótulos',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  enableSuggestions: true,
                  autocorrect: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateImage,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _isGenerating ? 'Gerando...' : 'Gerar Imagem',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Histórico',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _images.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma imagem gerada ainda',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
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
                                  height: 180,
                                )
                              : Image.network(
                                  src,
                                  fit: BoxFit.cover,
                                  height: 180,
                                );
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
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
                              child: Stack(
                                children: [
                                  Hero(tag: tag, child: preview),
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
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
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Imagem salva.',
                                                    ),
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
                                            icon: const Icon(
                                              Icons.share,
                                              color: Colors.white,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor: Colors.white,
                                                shape:
                                                    const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  16,
                                                                ),
                                                          ),
                                                    ),
                                                builder: (_) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.fromLTRB(
                                                          16,
                                                          16,
                                                          16,
                                                          24,
                                                        ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          'Detalhes da Geração',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        if (item.model !=
                                                            null) ...[
                                                          const Text(
                                                            'Modelo',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(item.model!),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                        ],
                                                        const Text(
                                                          'Prompt Utilizado',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          item.prompt ??
                                                              'Indisponível',
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.info_outline,
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
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _accountScreen() {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: SizedBox(
            height: kToolbarHeight,
            child: Center(
              child: SvgPicture.asset(Vectors.logo, height: 40, width: 40),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height:
                    kToolbarHeight + MediaQuery.of(context).padding.top + 50,
              ),
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.blue,
                child: const Icon(Icons.person, size: 60, color: Colors.white),
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
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.edit, color: AppColors.blue),
                      title: const Text(
                        'Alterar nome',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: _changeName,
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Sair',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () async {
                        await authService.value.signOut();
                        if (!mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const SplashPage()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0 ? _homeScreen() : _accountScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Criar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Minha Conta',
          ),
        ],
      ),
    );
  }
}
