import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HistoryService {
  Future<String> saveGenerated({
    required String uid,
    required String src,
    String? model,
    String? prompt,
    String? aspectRatio,
    String? temaSelecionado,
    String? subareaSelecionada,
    String? temaResolvido,
    String? subareaResolvida,
  }) async {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final ts = now.millisecondsSinceEpoch;

    final isDataUrl = src.startsWith('data:image/');
    String storagePath;
    Uint8List bytes;

    if (isDataUrl) {
      final header = src.substring(0, src.indexOf(','));
      final ext = header.contains('image/png')
          ? 'png'
          : header.contains('image/jpeg')
          ? 'jpg'
          : 'png';
      final b64 = src.split(',').last;
      bytes = base64Decode(b64);
      storagePath = 'images/$uid/$y/$m/$d/$ts.$ext';
    } else {
      bytes = Uint8List(0);
      storagePath = 'images/$uid/$y/$m/$d/$ts.png';
    }

    String downloadUrl;
    if (isDataUrl) {
      final ref = FirebaseStorage.instance.ref(storagePath);
      final meta = SettableMetadata(
        contentType: storagePath.endsWith('.jpg') ? 'image/jpeg' : 'image/png',
      );
      await ref.putData(bytes, meta);
      downloadUrl = await ref.getDownloadURL();
    } else {
      downloadUrl = src;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('images')
        .doc();

    await docRef.set({
      'createdAt': FieldValue.serverTimestamp(),
      'downloadUrl': downloadUrl,
      'storagePath': isDataUrl ? storagePath : null,
      'model': model,
      'prompt': prompt,
      'aspectRatio': aspectRatio,
      'temaSelecionado': temaSelecionado,
      'subareaSelecionada': subareaSelecionada,
      'temaResolvido': temaResolvido,
      'subareaResolvida': subareaResolvida,
    });

    return docRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> userImagesStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('images')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
