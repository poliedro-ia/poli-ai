import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class HistoryService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<void> saveGenerated({
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
    String finalUrl = src;
    if (src.startsWith('data:image/')) {
      final bytes = base64Decode(src.split(',').last);
      final id = _randId();
      final path = 'users/$uid/images/$id.png';
      final ref = _storage.ref().child(path);
      await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
      finalUrl = await ref.getDownloadURL();
    }
    final col = _db.collection('users').doc(uid).collection('images');
    await col.add({
      'src': finalUrl,
      'model': model,
      'prompt': prompt,
      'aspectRatio': aspectRatio,
      'temaSelecionado': temaSelecionado,
      'subareaSelecionada': subareaSelecionada,
      'temaResolvido': temaResolvido,
      'subareaResolvida': subareaResolvida,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamUserImages(String uid) {
    final q = _db
        .collection('users')
        .doc(uid)
        .collection('images')
        .orderBy('createdAt', descending: true)
        .limit(200);
    return q.snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'src': data['src'] as String? ?? '',
          'model': data['model'],
          'prompt': data['prompt'],
          'aspectRatio': data['aspectRatio'],
          'temaSelecionado': data['temaSelecionado'],
          'subareaSelecionada': data['subareaSelecionada'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    });
  }

  String _randId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return List.generate(20, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
