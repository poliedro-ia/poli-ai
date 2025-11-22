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
    final u =
        FirebaseAuth.instance.currentUser ??
        await FirebaseAuth.instance.authStateChanges().firstWhere(
          (x) => x != null,
        );
    await u!.getIdToken(true);
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

    String downloadUrl = src;
    String? storagePath;

    if (src.startsWith('data:image/')) {
      final bytes = _decodeDataUrl(src);
      final ext = _inferExt(src);
      final fileId = DateTime.now().millisecondsSinceEpoch.toString();
      storagePath = 'users/$uid/images/$fileId.$ext';
      final ref = _st.ref(storagePath);
      final meta = SettableMetadata(contentType: 'image/$ext');
      await ref.putData(bytes, meta);
      downloadUrl = await ref.getDownloadURL();
    }

    final doc = _fs.collection('users').doc(uid).collection('images').doc();
    final data = <String, dynamic>{
      'downloadUrl': downloadUrl,
      if (storagePath != null) 'storagePath': storagePath,
      'prompt': prompt,
      'promptUsado': prompt,
      'model': model,
      'aspectRatio': aspectRatio,
      'temaSelecionado': temaSelecionado,
      'subareaSelecionada': subareaSelecionada,
      'temaResolvido': temaResolvido,
      'subareaResolvida': subareaResolvida,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await doc.set(data);
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
