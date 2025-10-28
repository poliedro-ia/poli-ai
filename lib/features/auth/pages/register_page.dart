import 'package:flutter/material.dart';
import 'package:app/features/auth/auth_service.dart';
import 'package:app/features/auth/firebase_error_mapper.dart';
import 'package:app/features/auth/pages/login_page.dart';
import 'package:app/features/home/home_page.dart';
import 'package:app/core/utils/validators.dart';
import 'package:app/features/auth/ui/auth_ui.dart';

class Register extends StatefulWidget {
  final bool? darkInitial;
  const Register({super.key, this.darkInitial});
  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  late bool _dark;
  late AuthPalette _p;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  bool get _canSubmit =>
      _name.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _pass.text.isNotEmpty &&
      !_loading;

  @override
  void initState() {
    super.initState();
    _dark = widget.darkInitial ?? false;
    _p = AuthPalette(_dark);
    _name.addListener(() => setState(() {}));
    _email.addListener(() => setState(() {}));
    _pass.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant Register oldWidget) {
    super.didUpdateWidget(oldWidget);
    _p = AuthPalette(_dark);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final name = _name.text.trim();
    final email = _email.text.trim();
    final pass = _pass.text;

    final nameErr = Validators.requiredField(name, label: 'Nome');
    final emailErr = Validators.email(email);
    final passErr = Validators.password(pass);

    if (nameErr != null || emailErr != null || passErr != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos corretamente')),
      );
      return;
    }

    if (!Validators.emailDomainAllowed(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use um email @sistemapoliedro.com.br ou @p4ed.com'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await authService.value.createAccount(
        name: name,
        email: email,
        password: pass,
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
      appBar: AuthAppBar(
        p: _p,
        actionText: 'Login',
        onAction: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Login(darkInitial: _dark)),
        ),
      ),
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
                    'Criar conta',
                    style: TextStyle(
                      color: _p.textMain,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Preencha seus dados para começar a usar o PoliAI.',
                    style: TextStyle(color: _p.textSub),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: _p.textMain),
                    decoration: _p.dec('Nome completo'),
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 18),
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
                              'Criar conta',
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
                        'Já tem uma conta? ',
                        style: TextStyle(
                          color: _p.textMain,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Login(darkInitial: _dark),
                          ),
                        ),
                        child: Text(
                          'Entrar',
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
