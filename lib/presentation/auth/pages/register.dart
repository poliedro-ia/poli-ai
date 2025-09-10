import 'package:app/common/widgets/appbar/basic_app_bar.dart';
import 'package:app/common/widgets/button/auth_button.dart';
import 'package:app/core/configs/assets/vectors.dart';
import 'package:app/core/configs/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _obscure = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BasicAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              SvgPicture.asset(Vectors.logo, height: 40, width: 40),
              const SizedBox(height: 26),
              _title(),
              const SizedBox(height: 8),
              _subtitle(),
              const SizedBox(height: 40),
              _nameField(),
              const SizedBox(height: 18),
              _emailField(),
              const SizedBox(height: 18),
              _passwordField(),
              const SizedBox(height: 28),
              AuthButton(onPressed: () {}, title: 'Criar Conta'),
              const SizedBox(height: 22),
              _orDivider(),
              const SizedBox(height: 14),
              _signInRow(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF7F7F7),
    );
  }

  Widget _title() {
    return const Text(
      'Registrar',
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
        fontSize: 32,
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
          fontWeight: FontWeight.w500,
          color: Color(0xFF7D7D7D),
          height: 1.2,
        ),
        children: [
          TextSpan(text: 'Digite Seu '),
          TextSpan(
            text: 'nome',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ', '),
          TextSpan(
            text: 'email',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' e '),
          TextSpan(
            text: 'senha',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _nameField() {
    return TextField(
      textInputAction: TextInputAction.next,
      decoration: _fieldDecoration('Nome Completo'),
    );
  }

  Widget _emailField() {
    return TextField(
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: _fieldDecoration('Email'),
    );
  }

  Widget _passwordField() {
    return TextField(
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
              fontWeight: FontWeight.w600,
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
          onPressed: () {},
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
