import 'package:app/features/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// import 'features/splash/splash_page.dart'; // manter comentado por enquanto

const bool kBypassSplash = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Text(
          'UI Error: ${details.exceptionAsString()}',
          style: const TextStyle(color: Colors.red, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  };

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduImage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E6C86)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      ),
      home: const SplashPage(),
      // quando tudo ok, troque para: home: const SplashPage(),
    );
  }
}

/// Tela de fumaça: garante que o app está renderizando
class HomeSmoke extends StatelessWidget {
  const HomeSmoke({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Renderizou com sucesso 👑')),
    );
  }
}
