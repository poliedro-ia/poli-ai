import 'package:app/core/configs/theme/colors.dart';
import 'package:app/features/auth/auth_service.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  int _currentIndex = 0;
  final TextEditingController _promptController = TextEditingController();

  bool _isGenerating = false;
  List<String> _images = [];

  Future<void> _generateImage() async {
    if (_promptController.text.isEmpty) return;

    setState(() => _isGenerating = true);

    await Future.delayed(const Duration(seconds: 2)); // simulação de geração

    setState(() {
      _images.insert(
        0,
        "https://placehold.co/600x400/png?text=${_promptController.text}",
      );
      _isGenerating = false;
      _promptController.clear();
    });
  }

  Widget _homeScreen() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            "Crie sua imagem com IA",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _promptController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: "Descreva a imagem que deseja gerar...",
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateImage,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: "BrandingSF",
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(_isGenerating ? "Gerando..." : "Gerar Imagem"),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Histórico",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _images.isEmpty
                ? const Center(
                    child: Text(
                      "Nenhuma imagem gerada ainda",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(_images[index], fit: BoxFit.cover),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _accountScreen() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          const CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.blue,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            authService.value.currentUser?.displayName ?? "Usuário",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            authService.value.currentUser?.email ?? "",
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 30),
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.blue),
            title: const Text("Alterar nome"),
            onTap: () {
              // lógica para alterar nome
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Sair"),
            onTap: () async {
              await authService.value.signOut();
              if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0 ? _homeScreen() : _accountScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Criar",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Minha Conta",
          ),
        ],
      ),
    );
  }
}
