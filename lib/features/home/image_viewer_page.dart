import 'dart:convert';
import 'package:flutter/material.dart';

class ImageViewerPage extends StatelessWidget {
  final String src;
  final String tag;
  const ImageViewerPage({super.key, required this.src, required this.tag});

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
