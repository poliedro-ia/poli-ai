import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'package:app/features/home/home_page.dart';
import 'package:app/core/configs/theme/theme.dart';
import 'package:app/core/configs/theme/theme_controller.dart';

Future<void> _init() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider(
        '6Lf6se0rAAAAAOSe2SBEeO0qL7Rb_3BrHiO4SKgH',
      ),
    );
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } else {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _init();
  await ThemeController.instance.load();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDark,
      builder: (_, isDark, __) {
        final baseLight = AppTheme.light;
        final baseDark = AppTheme.dark;

        const buttonTextStyle = TextStyle(
          fontFamily: 'BrandingSF',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );

        final themeLight = baseLight.copyWith(
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(textStyle: buttonTextStyle),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(textStyle: buttonTextStyle),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(textStyle: buttonTextStyle),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(textStyle: buttonTextStyle),
          ),
        );

        final themeDark = baseDark.copyWith(
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(textStyle: buttonTextStyle),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(textStyle: buttonTextStyle),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(textStyle: buttonTextStyle),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(textStyle: buttonTextStyle),
          ),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeLight,
          darkTheme: themeDark,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const HomePage(),
        );
      },
    );
  }
}
