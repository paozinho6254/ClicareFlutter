import 'package:clicare/screens/clinic/clinic_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

// Importe suas telas e providers
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ucyezowavvcolkyjfium.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjeWV6b3dhdnZjb2xreWpmaXVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0NzQxOTAsImV4cCI6MjA3OTA1MDE5MH0.257gl7chhDjrzBIgzlX659zBRqdcgAjfxXhqIxRFAaw',
  );

  // 2. CORREÇÃO DO ERRO: Inicializa a formatação de datas para Português
  await initializeDateFormatting('pt_BR', null);

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
// main.dart - Dentro do Consumer<AuthProvider>
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const SplashScreen();
          } else if (!auth.isLoggedIn) {
            return const LoginScreen();
          } else {
            // ROTEAMENTO
            final role = auth.userProfile?.role;

            if (role == UserType.clinic) {
              return const ClinicHomeScreen();
            } else if (role == UserType.patient) {
              // return const PatientHomeScreen(); // Se já tiver criado
              return const CliCareHome();
            } else {
              // --- AQUI ESTÁ A CORREÇÃO ---
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.orange),
                        const SizedBox(height: 20),
                        Text(
                          "Tipo de usuário desconhecido ou incompleto.\nRole detectada: $role",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        // Mostra dados brutos para debug (se tiver)
                        Text(
                          "Nome: ${auth.userProfile?.nomeExibicao ?? 'Nulo'}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text("Sair e Tentar Novamente"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: () {
                            // Força o logout para limpar o estado
                            Provider.of<AuthProvider>(context, listen: false).logout();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }
}