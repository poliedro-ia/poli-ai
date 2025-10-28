import 'package:firebase_auth/firebase_auth.dart';

String mapFirebaseAuthError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email já cadastrado';
      case 'invalid-email':
        return 'Email inválido';
      case 'weak-password':
        return 'Senha fraca';
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente mais tarde.';
      default:
        return 'Erro de autenticação';
    }
  }
  return 'Falha inesperada';
}
