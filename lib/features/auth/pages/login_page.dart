// lib/features/auth/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:app/features/auth/auth_service.dart';
import 'package:app/features/auth/firebase_error_mapper.dart';
import 'package:app/features/auth/pages/forgot_password_page.dart';
import 'package:app/features/auth/pages/register_page.dart';
import 'package:app/features/home/home_page.dart';
import 'package:app/core/configs/assets/images.dart';

class Login extends StatefulWidget {
  final bool? darkInitial;
  const Login({super.key, this.darkInitial});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late bool _dark;

  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  bool get _canSubmit =>
      _email.text.trim().isNotEmpty && _pass.text.isNotEmpty && !_loading;

  @override
  void initState() {
    super.initState();
    _dark = widget.darkInitial ?? false;
    _email.addListener(() => setState(() {}));
    _pass.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Color get _bg => _dark ? const Color(0xff0B0E19) : const Color(0xffF7F8FA);
  Color get _card => _dark ? const Color(0xff121528) : Colors.white;
  Color get _border =>
      _dark ? const Color(0xff1E2233) : const Color(0xffE5EAF3);
  Color get _textMain => _dark ? Colors.white : const Color(0xff0B1220);
  Color get _textSub =>
      _dark ? const Color(0xff99A3BC) : const Color(0xff5A6477);
  Color get _fieldBg => _dark ? const Color(0xff0F1220) : Colors.white;
  Color get _fieldBorder =>
      _dark ? const Color(0xff23263A) : const Color(0xffE5EAF3);
  Color get _cta => const Color(0xff2563EB);
  Color get _barBg => _dark ? const Color(0xff101425) : Colors.white;

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: _fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      hintStyle: TextStyle(color: _textSub),
      labelStyle: TextStyle(color: _textSub),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _cta, width: 1.4),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _loading = true);
    try {
      await authService.value.signIn(
        email: _email.text.trim(),
        password: _pass.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = mapFirebaseAuthError(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: _barBg,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 76,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (_) => false,
            );
          },
          child: Image.asset(
            _dark ? Images.whiteLogo : Images.logo,
            height: 100,
            width: 100,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton(
            onPressed: () {}, // já estamos no login
            style: FilledButton.styleFrom(
              backgroundColor: _cta,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Login'),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border.withOpacity(0.7)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
                boxShadow: [
                  if (!_dark)
                    const BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 28,
                      offset: Offset(0, 16),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Entrar',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: _textMain,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Use seu e-mail e senha para acessar sua conta.',
                    style: TextStyle(color: _textSub),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: _textMain),
                    decoration: _dec('Email'),
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pass,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(color: _textMain),
                    decoration: _dec('Senha').copyWith(
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          splashRadius: 22,
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: _textSub,
                          ),
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Esqueci minha senha',
                        style: TextStyle(
                          color: _dark ? const Color(0xFF9FB4FF) : _cta,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _canSubmit ? _submit : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _cta,
                        disabledBackgroundColor: _dark
                            ? const Color(0xFF1B2A52)
                            : const Color(0xFFCBD8FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: _border.withOpacity(0.8),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Ou',
                          style: TextStyle(
                            color: _textSub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: _border.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Não tem uma conta? ',
                        style: TextStyle(
                          color: _textMain,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Register(darkInitial: _dark),
                            ),
                          );
                        },
                        child: Text(
                          'Registrar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _cta,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
