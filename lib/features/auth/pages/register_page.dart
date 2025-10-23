import 'package:flutter/material.dart';
import 'package:app/features/auth/auth_service.dart';
import 'package:app/features/auth/firebase_error_mapper.dart';
import 'package:app/features/auth/pages/login_page.dart';
import 'package:app/features/home/home_page.dart';
import 'package:app/core/configs/assets/images.dart';
import 'package:app/core/utils/validators.dart';

class Register extends StatefulWidget {
  final bool? darkInitial;
  const Register({super.key, this.darkInitial});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  late bool _dark;

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
    _name.addListener(() => setState(() {}));
    _email.addListener(() => setState(() {}));
    _pass.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
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
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => Login(darkInitial: _dark)),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: _cta,
              foregroundColor: Colors.white,
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
                    'Criar conta',
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
                    'Preencha seus dados para começar a usar o PoliAI.',
                    style: TextStyle(color: _textSub),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: _textMain),
                    decoration: _dec('Nome completo'),
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _canSubmit ? _submit : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _cta,
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
                        'Já tem uma conta? ',
                        style: TextStyle(
                          color: _textMain,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Login(darkInitial: _dark),
                            ),
                          );
                        },
                        child: Text(
                          'Entrar',
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
