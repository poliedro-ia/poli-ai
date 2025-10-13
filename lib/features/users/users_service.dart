import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersService {
  Future<void> ensureUserDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();
    final now = FieldValue.serverTimestamp();
    final search = _buildSearch(user);
    if (!snap.exists) {
      await ref.set({
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'createdAt': now,
        'disabled': false,
        'role': 'user',
        'search': search,
      });
      return;
    }
    await ref.update({
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'search': search,
    });
  }

  List<String> _buildSearch(User u) {
    final e = (u.email ?? '').toLowerCase();
    final n = (u.displayName ?? '').toLowerCase();
    final tokens = <String>{};
    void addTokens(String s) {
      final parts = s.split(RegExp(r'[\s@._-]+')).where((p) => p.isNotEmpty);
      for (final p in parts) {
        for (int i = 1; i <= p.length; i++) {
          tokens.add(p.substring(0, i));
        }
      }
    }

    addTokens(e);
    addTokens(n);
    return tokens.toList();
  }
}
