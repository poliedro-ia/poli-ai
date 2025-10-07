import 'package:app/common/widgets/button/auth_button.dart';
import 'package:app/core/configs/assets/vectors.dart';
import 'package:app/core/configs/theme/colors.dart';
import 'package:app/features/auth/auth_service.dart';
import 'package:app/features/auth/pages/login_page.dart';
import 'package:app/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/core/utils/validators.dart';
import 'package:app/features/auth/firebase_error_mapper.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF8A8A8E),
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF1E6C86), width: 1.6),
      ),
    );
  }

  Future<void> register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    if (Validators.requiredField(name, label: 'Nome') != null ||
        Validators.email(email) != null ||
        Validators.password(pass) != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos corretamente')),
      );
      return;
    }

    if (!Validators.emailDomainAllowed(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Use um email @sistemapoliedro.com.br ou @p4ed.com'),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await authService.value.createAccount(
        name: name,
        email: email,
        password: pass,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = mapFirebaseAuthError(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: kToolbarHeight + MediaQuery.of(context).padding.top,
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),
                        _title(),
                        const SizedBox(height: 12),
                        _subtitle(),
                        const SizedBox(height: 40),
                        _nameField(),
                        const SizedBox(height: 18),
                        _emailField(),
                        const SizedBox(height: 18),
                        _passwordField(),
                        const SizedBox(height: 28),
                        AuthButton(
                          onPressed: _isLoading
                              ? null
                              : () async => await register(),
                          title: _isLoading ? 'Criando...' : 'Criar Conta',
                        ),
                        const SizedBox(height: 22),
                        _orDivider(),
                        const SizedBox(height: 14),
                        _signInRow(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: SizedBox(
              height: kToolbarHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Center(
                    child: SvgPicture.asset(
                      Vectors.logo,
                      height: 40,
                      width: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title() {
    return const Text(
      'Registrar',
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
        fontSize: 36,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _subtitle() {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF7D7D7D),
          height: 1.2,
        ),
        children: [
          TextSpan(text: 'Digite seu '),
          TextSpan(
            text: 'Nome',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          TextSpan(text: ', '),
          TextSpan(
            text: 'Email',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          TextSpan(text: ' e '),
          TextSpan(
            text: 'Senha',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _nameField() {
    return TextField(
      controller: _nameController,
      textInputAction: TextInputAction.next,
      decoration: _fieldDecoration('Nome Completo'),
    );
  }

  Widget _emailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: _fieldDecoration('Email'),
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      decoration: _fieldDecoration('Senha').copyWith(
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            splashRadius: 22,
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }

  Widget _orDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF000000).withOpacity(0.08),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Ou',
            style: TextStyle(
              color: Color(0xFF7D7D7D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF000000).withOpacity(0.08),
          ),
        ),
      ],
    );
  }

  Widget _signInRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Já tem uma conta? ',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const Login(),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
          ),
          child: const Text(
            'Entrar',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF288CE9),
            ),
          ),
        ),
      ],
    );
  }
}
