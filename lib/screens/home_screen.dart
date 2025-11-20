import 'package:clicare/screens/patient/doctor_search_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/next_appointment_card.dart';

class CliCareHome extends StatelessWidget {
  const CliCareHome({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos 'Provider.of' para obter acesso ao AuthProvider.
    // 'listen: false' é usado em métodos, mas aqui no build,
    // 'listen: true' (o padrão) garante que a UI se reconstrua se o usuário mudar.
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CABEÇALHO DINÂMICO ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Saudação com o nome do usuário logado
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Bem-vindo(a) de volta,",
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // Pega o nome do usuário do provider.
                        // Usa 'Usuário' como um valor padrão caso o nome seja nulo.
                        authProvider.userProfile?.nomeExibicao ?? 'Carregando...',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00BFA6),
                        ),
                      ),
                    ],
                  ),
                  // Botão de Logout
                  IconButton(
                    tooltip: 'Sair',
                    icon: const Icon(Icons.logout, color: Colors.black54, size: 28),
                    onPressed: () {
                      // Chama o método de logout do provider.
                      // 'listen: false' é usado aqui porque estamos em um callback,
                      // não na construção de um widget.
                      Provider.of<AuthProvider>(context, listen: false).logout();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- RESTO DO SEU LAYOUT ORIGINAL ---

              // Campo de pesquisa
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Pesquisar médicos, exames...",
                    border: InputBorder.none,
                    icon: Icon(Icons.search),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botão de consulta rápida
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DoctorSearchScreen(),
                      ),
                    );
                  },
                  icon: Icon(CupertinoIcons.clock, color: Colors.white, size: 24,),
                  label: const Text(
                    "Agendar Consulta",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botões Doutores e Remédios
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _homeOption(Icons.person_outline, "Doutores"),
                  _homeOption(Icons.medical_services_outlined, "Remédios"),
                ],
              ),

              const SizedBox(height: 30),

              // Próxima consulta (Upcoming Appointment)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Próxima Consulta",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Ver todas",
                    style: TextStyle(color: Colors.teal, fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const NextAppointmentCard(),

              const SizedBox(height: 30),

              // Top Doctors
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Principais Médicos",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Ver todos",
                    style: TextStyle(color: Colors.teal, fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFE0E0E0),
                      // TODO: Trocar por uma imagem real do médico
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dr. Ana",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            "Especialista de Pele | Hospital",
                            style: TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text("4.9"),
                            ],
                          )
                        ],
                      ),
                    ),
                    const Icon(Icons.favorite, color: Colors.teal),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),

      // Barra inferior
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF00BFA6),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined), label: "Assistente AI"),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital_outlined), label: "Clínica"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: "Perfil"),
        ],
      ),
    );
  }

  // Função auxiliar para os botões "Doutores" e "Remédios"
  Widget _homeOption(IconData icon, String label) {
    return Container(
      width: 140,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF00BFA6)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}