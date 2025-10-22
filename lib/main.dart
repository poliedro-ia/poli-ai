import 'dart:async';
import 'package:app/core/configs/theme/theme_controller.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/firebase_options.dart';
import 'package:app/features/home/home_page.dart';

Future<void> _init() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('SEU_RECAPTCHA_V3_SITE_KEY'),
    );
  } else {
    await FirebaseAppCheck.instance.activate();
  }
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  await ThemeController.instance.load();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDark,
      builder: (_, dark, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
            colorSchemeSeed: const Color(0xff2563EB),
            useMaterial3: true,
          ),
          home: const HomePage(),
        );
      },
    );
  }
}
