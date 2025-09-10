import 'package:app/common/widgets/button/auth_button.dart';
import 'package:app/core/configs/assets/images.dart';
import 'package:app/core/configs/assets/vectors.dart';
import 'package:app/core/configs/theme/colors.dart';
import 'package:app/presentation/auth/pages/login.dart';
import 'package:app/presentation/auth/pages/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignupOrSignin extends StatelessWidget {
  const SignupOrSignin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          AppBar(),
          Align(
            alignment: Alignment.topRight,
            child: SvgPicture.asset(Vectors.topPattern),
          ),

          Align(
            alignment: Alignment.bottomRight,
            child: SvgPicture.asset(Vectors.bottomPattern),
          ),

          Align(
            alignment: Alignment.bottomLeft,
            child: Image.asset(
              Images.authBG,
              width: 350, // largura desejada
              height: 400, // altura desejada
              fit: BoxFit.cover, // ou BoxFit.contain, para manter proporção
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 200, 40, 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        Vectors.logo,
                        width: 75,
                        height: 75,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 55),

                      const Text(
                        'Sua Ideia Em Imagem',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                          fontSize: 28,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'PoliAI é uma plataforma de geração de imagens com inteligência artificial',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 30),

                      Row(
                        children: [
                          Expanded(
                            child: AuthButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        const Register(),
                                  ),
                                );
                              },
                              title: 'Registrar',
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        const Login(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Entrar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 20,
                                  color: AppColors.black,
                                ),
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
        ],
      ),
    );
  }
}
