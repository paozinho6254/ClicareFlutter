import 'package:flutter/material.dart';
import 'clinic_register_screen.dart';
import 'patient_register_screen.dart';

class RegisterChoiceScreen extends StatelessWidget {
  const RegisterChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF319F86);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor], // Ou seu gradiente preferido
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView( // Adicionado para evitar overflow em telas pequenas
            child: Container(
              width: 420,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, 6))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cadastrar no Portal',
                    style: TextStyle(fontSize: 26, color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Quem você é?',
                    style: TextStyle(color: Color(0xFF666), fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),

                  // Botão Clínica
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ClinicRegisterScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Clínica', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botão Paciente
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const PatientRegisterScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryColor, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Paciente', style: TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- NOVO BOTÃO DE VOLTAR PARA LOGIN ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Já tem uma conta? ", style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () {
                          // Volta para a tela anterior (que deve ser o Login)
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Entrar",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
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
    );
  }
}