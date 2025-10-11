import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AppCheckDebugPage extends StatefulWidget {
  const AppCheckDebugPage({super.key});
  @override
  State<AppCheckDebugPage> createState() => _AppCheckDebugPageState();
}

class _AppCheckDebugPageState extends State<AppCheckDebugPage> {
  String? uid;
  String firestoreResult = '';
  String storageResult = '';

  Future<void> _load() async {
    uid = FirebaseAuth.instance.currentUser?.uid ?? 'sem_login';
    setState(() {});
  }

  Future<void> _testFirestore() async {
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) {
        firestoreResult = 'sem_login';
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(u.uid)
            .collection('debug')
            .doc('probe')
            .set({'ts': now});
        firestoreResult = 'ok';
      }
    } catch (e) {
      firestoreResult = 'erro:$e';
    }
    setState(() {});
  }

  Future<void> _testStorage() async {
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) {
        storageResult = 'sem_login';
      } else {
        final bytes = Uint8List.fromList(List<int>.generate(16, (i) => i));
        final ref = FirebaseStorage.instance.ref('debug/${u.uid}/probe.bin');
        await ref.putData(
          bytes,
          SettableMetadata(contentType: 'application/octet-stream'),
        );
        await ref.getDownloadURL();
        storageResult = 'ok';
      }
    } catch (e) {
      storageResult = 'erro:$e';
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('UID'),
            const SizedBox(height: 6),
            SelectableText(uid ?? ''),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testFirestore,
              child: const Text('Teste Firestore'),
            ),
            const SizedBox(height: 8),
            Text(firestoreResult),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testStorage,
              child: const Text('Teste Storage'),
            ),
            const SizedBox(height: 8),
            Text(storageResult),
          ],
        ),
      ),
    );
  }
}
