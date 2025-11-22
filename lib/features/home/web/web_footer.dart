import 'package:flutter/material.dart';

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff0B0E19),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: const [
              Text(
                'PoliAI • Ferramenta para criação de imagens educacionais',
                style: TextStyle(color: Color(0xff97A0B5)),
              ),
              SizedBox(height: 6),
              Text(
                'Física • Matemática • Ciências',
                style: TextStyle(color: Color(0xff6F7891)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
