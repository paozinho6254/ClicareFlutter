import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // Fundo com a cor da sua marca
      backgroundColor: Color(0xFF319F86), // Cor verde do seu projeto
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aqui você pode colocar a sua logo
            // Supondo que você adicionou 'logoClicare.png' na pasta 'assets/images/'
            // Image.asset('assets/images/logoClicare.png', width: 150),

            // Ícone genérico se não tiver a imagem
            Icon(Icons.local_hospital, size: 100, color: Colors.white),

            SizedBox(height: 20),

            // Indicador de carregamento
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}