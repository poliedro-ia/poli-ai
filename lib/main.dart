import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'package:app/features/home/home_page.dart';

Future<void> _initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await FirebaseAppCheck.instance.activate();
  } catch (e) {
    // App Check falhou (ex.: provider/SDK no Console, cache, extensão bloqueando).
    // Continuamos sem App Check para não derrubar o app.
    // Se quiser logar: debugPrint('AppCheck init failed: $e');
  }

  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (_) {}
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  runZonedGuarded(
    () async {
      String? fatal;
      try {
        await _initFirebase();
      } catch (e, s) {
        fatal = '$e\n$s';
      }
      runApp(fatal == null ? const _App() : _ErrorApp(message: fatal));
    },
    (e, s) {
      runApp(_ErrorApp(message: '$e\n$s'));
    },
  );
}

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class _ErrorApp extends StatelessWidget {
  final String message;
  const _ErrorApp({required this.message});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xff0B0E19),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                'Falha ao iniciar o app:\n\n$message',
                style: const TextStyle(color: Colors.white, height: 1.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}