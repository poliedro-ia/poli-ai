import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final ValueNotifier<bool> isDark = ValueNotifier<bool>(true);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    isDark.value = p.getBool('isDark') ?? true;
  }

  Future<void> setDark(bool v) async {
    isDark.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('isDark', v);
  }

  Future<void> toggle() => setDark(!isDark.value);
}
