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

  String _fileName() => 'PoliAI_${DateTime.now().millisecondsSinceEpoch}.png';

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
            icon: const Icon(Icons.download),
            onPressed: () async {
              await downloadImage(src, filename: _fileName());
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Imagem salva.')));
              }
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
