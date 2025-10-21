import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_saver/file_saver.dart';

class SmartImage extends StatefulWidget {
  final String src;
  final BoxFit fit;
  final double? width, height;
  const SmartImage({
    super.key,
    required this.src,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  static Future<void> download(
    String src, {
    String filename = 'image.png',
  }) async {
    try {
      if (src.startsWith('data:image/')) {
        final bytes = _decodeDataUrl(src);
        await FileSaver.instance.saveFile(
          name: filename,
          bytes: bytes,
          mimeType: _mimeFromName(filename),
        );
        return;
      }
      final data = await _getBytesFromAny(src);
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: data,
        mimeType: _mimeFromName(filename),
      );
    } catch (_) {}
  }

  static Future<String> _resolveUrl(String src) async {
    if (src.startsWith('data:image/') || src.startsWith('http')) return src;
    if (src.startsWith('gs://'))
      return FirebaseStorage.instance.refFromURL(src).getDownloadURL();
    return FirebaseStorage.instance.ref(src).getDownloadURL();
  }

  static Future<Uint8List> _getBytesFromAny(String src) async {
    if (src.startsWith('data:image/')) return _decodeDataUrl(src);
    if (src.startsWith('gs://'))
      return (await FirebaseStorage.instance.refFromURL(src).getData()) ??
          Uint8List(0);
    if (src.startsWith('http')) {
      try {
        final uri = Uri.parse(src);
        final i = uri.path.indexOf('/o/');
        final hasToken = uri.queryParameters['token'] != null;
        if (i != -1 && hasToken) {
          final enc = uri.path.substring(i + 3);
          final path = Uri.decodeComponent(enc);
          return (await FirebaseStorage.instance.ref(path).getData()) ??
              Uint8List(0);
        }
      } catch (_) {}
      return Uint8List(0);
    }
    return (await FirebaseStorage.instance.ref(src).getData()) ?? Uint8List(0);
  }

  static Uint8List _decodeDataUrl(String dataUrl) {
    final idx = dataUrl.indexOf(',');
    return Uint8List.fromList(base64Decode(dataUrl.substring(idx + 1)));
  }

  static MimeType _mimeFromName(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return MimeType.jpeg;
    if (n.endsWith('.svg')) return MimeType.avi;
    if (n.endsWith('.png')) return MimeType.png;
    return MimeType.other;
  }

  @override
  State<SmartImage> createState() => _SmartImageState();
}

class _SmartImageState extends State<SmartImage> {
  late Future<String> _url;

  @override
  void initState() {
    super.initState();
    _url = SmartImage._resolveUrl(widget.src);
  }

  @override
  void didUpdateWidget(covariant SmartImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) _url = SmartImage._resolveUrl(widget.src);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.src.startsWith('data:image/')) {
      final bytes = SmartImage._decodeDataUrl(widget.src);
      return Image.memory(
        bytes,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: _err,
      );
    }
    return FutureBuilder<String>(
      future: _url,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) return _ph();
        if (!s.hasData) return _err(context, null, null);
        final u = s.data!;
        if (u.startsWith('http')) {
          return Image.network(
            u,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            loadingBuilder: (c, child, p) => p == null ? child : _ph(),
            errorBuilder: _err,
          );
        }
        if (u.startsWith('data:image/')) {
          final b = SmartImage._decodeDataUrl(u);
          return Image.memory(
            b,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            errorBuilder: _err,
          );
        }
        return _err(context, null, null);
      },
    );
  }

  Widget _ph() => Container(
    color: Colors.black.withOpacity(0.06),
    alignment: Alignment.center,
    child: Icon(Icons.image, color: Colors.white.withOpacity(0.5)),
  );

  Widget _err(BuildContext _, Object? __, StackTrace? ___) => Container(
    color: Colors.black.withOpacity(0.08),
    alignment: Alignment.center,
    child: Icon(
      Icons.broken_image_outlined,
      color: Colors.white.withOpacity(0.6),
    ),
  );
}
