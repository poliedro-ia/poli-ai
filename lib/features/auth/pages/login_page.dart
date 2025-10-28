import 'package:flutter/material.dart';
import 'package:app/features/auth/auth_service.dart';
import 'package:app/features/auth/firebase_error_mapper.dart';
import 'package:app/features/auth/pages/forgot_password_page.dart';
import 'package:app/features/auth/pages/register_page.dart';
import 'package:app/features/home/home_page.dart';
import 'package:app/features/auth/ui/auth_ui.dart';

class Login extends StatefulWidget {
  final bool? darkInitial;
  const Login({super.key, this.darkInitial});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late bool _dark;
  late AuthPalette _p;

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
    _p = AuthPalette(_dark);
    _email.addListener(() => setState(() {}));
    _pass.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant Login oldWidget) {
    super.didUpdateWidget(oldWidget);
    _p = AuthPalette(_dark);
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    _p = AuthPalette(_dark);
    return Scaffold(
      backgroundColor: _p.bg,
      appBar: AuthAppBar(p: _p, actionText: 'Login', onAction: () {}),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
            child: AuthCard(
              p: _p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Entrar',
                    style: TextStyle(
                      color: _p.textMain,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Use seu e-mail e senha para acessar sua conta.',
                    style: TextStyle(color: _p.textSub),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: _p.textMain),
                    decoration: _p.dec('Email'),
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pass,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(color: _p.textMain),
                    decoration: _p
                        .dec('Senha')
                        .copyWith(
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: IconButton(
                              splashRadius: 22,
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: _p.textSub,
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
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      ),
                      child: Text(
                        'Esqueci minha senha',
                        style: TextStyle(
                          color: _dark ? const Color(0xFF9FB4FF) : _p.cta,
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
                        backgroundColor: _p.cta,
                        disabledBackgroundColor: _dark
                            ? const Color(0xFF1B2A52)
                            : const Color(0xFFCBD8FF),
                        foregroundColor: Colors.white,
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
                          color: _p.border.withOpacity(0.8),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Ou',
                          style: TextStyle(
                            color: _p.textSub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: _p.border.withOpacity(0.8),
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
                          color: _p.textMain,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Register(darkInitial: _dark),
                          ),
                        ),
                        child: Text(
                          'Registrar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _p.cta,
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
