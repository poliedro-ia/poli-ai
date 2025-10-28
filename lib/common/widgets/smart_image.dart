import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SmartImage extends StatelessWidget {
  final String src;
  final String? storagePath;
  final BoxFit fit;
  final double? height;
  final double? width;

  const SmartImage({
    super.key,
    required this.src,
    this.storagePath,
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

    if (storagePath != null && storagePath!.isNotEmpty) {
      return FutureBuilder<_Resolved>(
        future: _resolveFromStorage(storagePath!),
        builder: (context, snap) {
          if (snap.hasError) return _error();
          if (!snap.hasData) return _loader();
          final r = snap.data!;
          if (r.bytes != null) {
            return Image.memory(
              r.bytes!,
              fit: fit,
              height: height,
              width: width,
            );
          }
          if (r.url != null && r.url!.isNotEmpty) {
            return Image.network(
              r.url!,
              fit: fit,
              height: height,
              width: width,
              loadingBuilder: _loading,
              errorBuilder: _errBuilder,
            );
          }
          return _error();
        },
      );
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

  Future<_Resolved> _resolveFromStorage(String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    try {
      final data = await ref.getData(20971520);
      if (data != null && data.isNotEmpty) {
        return _Resolved(bytes: data);
      }
    } catch (_) {}
    try {
      final url = await ref.getDownloadURL();
      return _Resolved(url: url);
    } catch (_) {}
    return _Resolved();
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

class _Resolved {
  final Uint8List? bytes;
  final String? url;
  _Resolved({this.bytes, this.url});
}
