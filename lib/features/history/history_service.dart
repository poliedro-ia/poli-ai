// lib/features/history/history_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

class HistoryService {
  final _fs = FirebaseFirestore.instance;
  final _st = FirebaseStorage.instance;

  Future<void> _ensureAuthAndAppCheck() async {
    // Aguarda usuário realmente logado
    final u =
        FirebaseAuth.instance.currentUser ??
        await FirebaseAuth.instance.authStateChanges().firstWhere(
          (x) => x != null,
        );

    // Garante token de ID fresco
    await u!.getIdToken(true);

    // Garante token do App Check (força refresh se necessário)
    await FirebaseAppCheck.instance.getToken(true);
  }

  Future<void> saveGenerated({
    required String uid,
    required String src,
    String? model,
    required String prompt,
    required String aspectRatio,
    required String temaSelecionado,
    required String subareaSelecionada,
    required String temaResolvido,
    required String subareaResolvida,
  }) async {
    await _ensureAuthAndAppCheck();

    final me = FirebaseAuth.instance.currentUser;
    if (me == null || me.uid != uid) {
      throw Exception(
        'Usuário não autenticado para salvar no Storage/Firestore',
      );
    }

    String finalUrl = src;

    if (src.startsWith('data:image/')) {
      final bytes = _decodeDataUrl(src);
      final ext = _inferExt(src);
      final fileId = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _st.ref('users/$uid/images/$fileId.$ext');

      final meta = SettableMetadata(contentType: 'image/$ext');
      await ref.putData(bytes, meta);
      finalUrl = await ref.getDownloadURL();
    }

    final doc = _fs.collection('users').doc(uid).collection('images').doc();
    await doc.set({
      'src': finalUrl,
      'prompt': prompt,
      'model': model,
      'aspect': aspectRatio,
      'tema': temaSelecionado,
      'subarea': subareaSelecionada,
      'temaResolved': temaResolvido,
      'subareaResolved': subareaResolvida,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Uint8List _decodeDataUrl(String dataUrl) {
    final base64Part = dataUrl.split(',').last;
    return base64Decode(base64Part);
  }

  String _inferExt(String dataUrl) {
    if (dataUrl.startsWith('data:image/png')) return 'png';
    if (dataUrl.startsWith('data:image/jpeg')) return 'jpg';
    if (dataUrl.startsWith('data:image/webp')) return 'webp';
    return 'png';
  }
}
