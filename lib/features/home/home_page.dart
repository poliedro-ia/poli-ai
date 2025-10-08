import 'package:app/core/configs/theme/colors.dart';
import 'package:app/core/configs/assets/vectors.dart';
import 'package:app/features/auth/auth_service.dart';
import 'package:app/features/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  int _currentIndex = 0;
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isGenerating = false;
  final List<String> _images = [];

  Future<void> _generateImage() async {
    if (_promptController.text.isEmpty) return;

    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _images.insert(
        0,
        "https://placehold.co/600x400/png?text=${_promptController.text}",
      );
      _isGenerating = false;
      _promptController.clear();
    });
  }

  Future<void> _changeName() async {
    final currentName = authService.value.currentUser?.displayName ?? '';
    _nameController.text = currentName;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Alterar Nome',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Digite seu novo nome',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.blue),
            ),
          ),
          TextButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, _nameController.text.trim());
              }
            },
            style: TextButton.styleFrom(backgroundColor: AppColors.blue),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName != null && newName != currentName) {
      try {
        await authService.value.currentUser?.updateDisplayName(newName);
        await authService.value.currentUser?.reload();
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nome alterado com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao alterar nome: $e')));
        }
      }
    }
  }

  Widget _homeScreen() {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: SizedBox(
            height: kToolbarHeight,
            child: Center(
              child: SvgPicture.asset(Vectors.logo, height: 40, width: 40),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height:
                    kToolbarHeight + MediaQuery.of(context).padding.top + 20,
              ),
              const Text(
                "Crie sua imagem educativa",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Descreva abaixo a imagem que deseja gerar",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _promptController,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText:
                        "Ex: Um átomo de hidrogênio com elétrons orbitando...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateImage,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _isGenerating ? "Gerando..." : "Gerar Imagem",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
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
                        itemBuilder: (context, index) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            _images[index],
                            fit: BoxFit.cover,
                            height: 180,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _accountScreen() {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: SizedBox(
            height: kToolbarHeight,
            child: Center(
              child: SvgPicture.asset(Vectors.logo, height: 40, width: 40),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height:
                    kToolbarHeight + MediaQuery.of(context).padding.top + 50,
              ),
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.blue,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                authService.value.currentUser?.displayName ?? "Usuário",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                authService.value.currentUser?.email ?? "",
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.edit, color: AppColors.blue),
                      title: Text(
                        "Alterar nome",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: _changeName,
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        "Sair",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () async {
                        await authService.value.signOut();
                        if (!mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const SplashPage()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _nameController.dispose();
    super.dispose();
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
