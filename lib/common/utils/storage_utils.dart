import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

class StorageUtils {
  static Future<String> resolveDownloadUrl({
    required String src,
    String? path,
  }) async {
    if (src.startsWith('http')) return src;
    final st = FirebaseStorage.instance;
    if (src.startsWith('gs://')) {
      return await st.refFromURL(src).getDownloadURL();
    }
    if ((path ?? '').isNotEmpty) {
      return await st.ref(path!).getDownloadURL();
    }
    return src;
  }

  static Future<void> downloadFromUrl(
    BuildContext context,
    String url, {
    required String filename,
  }) async {
    if (kIsWeb) {
      final a = html.AnchorElement(href: url)..download = filename;
      html.document.body!.append(a);
      a.click();
      a.remove();
      return;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download disponível no Web.')),
      );
    }
  }

  static Future<String> uploadPngBytes({
    required Uint8List bytes,
    required String storagePath,
  }) async {
    final ref = FirebaseStorage.instance.ref(storagePath);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    return ref.getDownloadURL();
  }

  static Future<void> downloadByUrl(String finalUrl, {required String filename}) async {}
}
