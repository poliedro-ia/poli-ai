import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(name.trim());
    await cred.user?.reload();
    return cred;
  }

  Future<void> sendPasswordReset(String email) =>
      firebaseAuth.sendPasswordResetEmail(email: email.trim());

  Future<void> sendEmailVerification() async {
    final u = firebaseAuth.currentUser;
    if (u != null && !u.emailVerified) await u.sendEmailVerification();
  }

  Future<void> signOut() => firebaseAuth.signOut();
}
