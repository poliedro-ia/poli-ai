import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

Future<Uint8List> _bytesFromSrc(String src) async {
  if (src.startsWith('data:image/')) {
    final base64Part = src.split(',').last;
    return base64Decode(base64Part);
  }
  final resp = await http.get(Uri.parse(src));
  if (resp.statusCode != 200) throw Exception('Falha ao baixar imagem');
  return resp.bodyBytes;
}

String _extFromSrc(String src) {
  if (src.startsWith('data:image/')) {
    final h = src.substring(0, src.indexOf(';'));
    if (h.contains('png')) return 'png';
    if (h.contains('jpeg') || h.contains('jpg')) return 'jpg';
    if (h.contains('webp')) return 'webp';
    return 'png';
  }
  final p = Uri.parse(src).path.toLowerCase();
  if (p.endsWith('.png')) return 'png';
  if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'jpg';
  if (p.endsWith('.webp')) return 'webp';
  return 'png';
}

Future<String?> downloadImage(String src, {String? filename}) async {
  final bytes = await _bytesFromSrc(src);
  final ext = _extFromSrc(src);
  final name = filename ?? 'imagem_educativa';
  final saved = await FileSaver.instance.saveFile(
    name: name,
    bytes: bytes,
    ext: ext,
    mimeType: MimeType.other,
  );
  return saved;
}

Future<void> shareImage(String src, {String? filename}) async {
  if (kIsWeb && !src.startsWith('http')) {
    await downloadImage(src, filename: filename);
    return;
  }
  if (kIsWeb && src.startsWith('http')) {
    await Share.share(src);
    return;
  }
  final bytes = await _bytesFromSrc(src);
  final ext = _extFromSrc(src);
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/${filename ?? 'imagem_educativa'}.$ext';
  final file = File(path);
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(path)]);
}
