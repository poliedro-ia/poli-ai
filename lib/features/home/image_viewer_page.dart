import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app/core/utils/media_utils.dart';

class ImageViewerPage extends StatelessWidget {
  final String src;
  final String tag;
  final String? model;
  final String? prompt;
  const ImageViewerPage({
    super.key,
    required this.src,
    required this.tag,
    this.model,
    this.prompt,
  });

  @override
  Widget build(BuildContext context) {
    final isDataUrl = src.startsWith('data:image/');
    Widget content;
    if (isDataUrl) {
      final base64Part = src.split(',').last;
      final bytes = base64Decode(base64Part);
      content = Image.memory(bytes, fit: BoxFit.contain);
    } else {
      content = Image.network(src, fit: BoxFit.contain);
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Visualização'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalhes da Geração',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (model != null) ...[
                          const Text(
                            'Modelo',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(model!),
                          const SizedBox(height: 12),
                        ],
                        const Text(
                          'Prompt Utilizado',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(prompt ?? 'Indisponível'),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              await downloadImage(src, filename: 'eduimage');
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Imagem salva.')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await shareImage(src, filename: 'eduimage');
            },
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: tag,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 5,
            child: content,
          ),
        ),
      ),
    );
  }
}
