import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart'; // Mude o nome do arquivo para home_screen.dart
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const CliCareApp(),
    ),
  );
}

class CliCareApp extends StatelessWidget {
  const CliCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CliCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00BFA6),
        scaffoldBackgroundColor: const Color(0xFFF2F7F9),
        useMaterial3: true,
      ),
      // A mágica acontece aqui:
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            // Enquanto verifica o token, mostra a tela de carregamento.
            return const SplashScreen();
          } else if (auth.isLoggedIn) {
            // Se o usuário está logado, mostra a tela principal.
            return const CliCareHome();
          } else {
            // Se não está logado, mostra a tela de login.
            return const LoginScreen();
          }
        },
      ),
    );
  }
}