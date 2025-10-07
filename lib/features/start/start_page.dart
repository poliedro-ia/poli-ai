import 'package:app/common/widgets/button/start_button.dart';
import 'package:app/core/configs/assets/images.dart';
import 'package:app/core/configs/assets/vectors.dart';
import 'package:app/core/configs/theme/colors.dart';
import 'package:app/features/auth/pages/signup_or_signin_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Start extends StatelessWidget {
  const Start({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 40, horizontal: 40),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Images.startBG),
                fit: BoxFit.cover,
                alignment: Alignment(0.35, 0.0),
              ),
            ),
          ),

          Container(color: Colors.black.withOpacity(0.1)),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // força colar no topo
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: SvgPicture.asset(Vectors.logo),
                ),

                const SizedBox(height: 490),

                Text(
                  'Sua Ideia Em Imagem',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.white,
                    fontSize: 28,
                  ),
                ),

                SizedBox(height: 21),

                Text(
                  'Personalize ilustrações educativas com Inteligência Artificial e transforme suas aulas em experiências visuais únicas.',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 28),

                StartButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const SignupOrSignin(),
                      ),
                    );
                  },
                  title: 'Começar',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
