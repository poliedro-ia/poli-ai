import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SmartImage extends StatelessWidget {
  final String src;
  final BoxFit fit;
  final double? height;
  final double? width;
  const SmartImage({
    super.key,
    required this.src,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (src.startsWith('data:image/')) {
      final bytes = base64Decode(src.split(',').last);
      return Image.memory(bytes, fit: fit, height: height, width: width);
    }
    if (src.startsWith('gs://')) {
      return FutureBuilder<String>(
        future: FirebaseStorage.instance.refFromURL(src).getDownloadURL(),
        builder: (context, snap) {
          if (snap.hasError) return _error();
          if (!snap.hasData) return _loader();
          return Image.network(
            snap.data!,
            fit: fit,
            height: height,
            width: width,
            loadingBuilder: _loading,
            errorBuilder: _errBuilder,
          );
        },
      );
    }
    return Image.network(
      src,
      fit: fit,
      height: height,
      width: width,
      loadingBuilder: _loading,
      errorBuilder: _errBuilder,
    );
  }

  Widget _loader() => const Center(
    child: SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  Widget _error() => const Center(child: Icon(Icons.broken_image_outlined));

  Widget _loading(BuildContext context, Widget child, ImageChunkEvent? p) {
    if (p == null) return child;
    return _loader();
  }

  Widget _errBuilder(BuildContext context, Object error, StackTrace? st) {
    return _error();
  }
}
