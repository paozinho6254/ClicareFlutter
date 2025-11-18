import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import 'manage_doctor_screen.dart';
import 'my_doctors_screen.dart'; // Importe a tela que criamos anteriormente

class ClinicHomeScreen extends StatefulWidget {
  const ClinicHomeScreen({super.key});

  @override
  State<ClinicHomeScreen> createState() => _ClinicHomeScreenState();
}

class _ClinicHomeScreenState extends State<ClinicHomeScreen> {
  int _selectedIndex = 0;

  // Lista de telas para navegação
  final List<Widget> _screens = [
    const ClinicDashboardTab(), // O Dashboard que vou criar abaixo
    const MyDoctorsScreen(),    // A tela de lista de médicos que já temos
    const Center(child: Text("Agenda Geral (Em Breve)")),
    const Center(child: Text("Perfil da Clínica (Em Breve)")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mantém o estado das abas para não recarregar tudo ao trocar
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        indicatorColor: const Color(0xFF319F86).withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF319F86)),
            label: 'Painel',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Color(0xFF319F86)),
            label: 'Médicos',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: Color(0xFF319F86)),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store, color: Color(0xFF319F86)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// --- WIDGET DO DASHBOARD (A TELA PRINCIPAL) ---

class ClinicDashboardTab extends StatelessWidget {
  const ClinicDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userProfile;
    final nomeClinica = user?.nomeExibicao ?? 'Clínica';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bem-vindo de volta,", style: TextStyle(color: Colors.grey, fontSize: 14)),
            Text(nomeClinica, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cards de Estatísticas Rápidas
            const Text("Visão Geral", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                    label: "Hoje",
                    value: "0", // Futuro: Count do banco
                    context: context
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    label: "Realizadas",
                    value: "0", // Futuro: Count do banco
                    context: context
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                    icon: Icons.people,
                    color: const Color(0xFF319F86),
                    label: "Médicos",
                    value: "-", // Pode buscar da lista
                    context: context
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 2. Atalhos Rápidos
            const Text("Ações Rápidas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(context, Icons.person_add, "Novo Médico", () {
                    // Navega para a aba de médicos (index 1) ou abre modal direto
                    // Aqui um exemplo simples abrindo a tela de cadastro
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageDoctorScreen()));
                    // Nota: precisa importar o manage_doctor_screen.dart
                  }),
                  _buildActionButton(context, Icons.block, "Bloquear Data", () {}),
                  _buildActionButton(context, Icons.settings, "Configurar", () {}),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Próximos Agendamentos (Resumo)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Próximos Pacientes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: (){}, child: const Text("Ver todos"))
              ],
            ),

            // Placeholder para quando não tem consultas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)
              ),
              child: Column(
                children: const [
                  Icon(Icons.event_busy, size: 40, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Sem agendamentos para hoje", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Auxiliar: Card de Estatística
  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required BuildContext context
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Widget Auxiliar: Botão de Ação
  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF319F86).withOpacity(0.1),
            child: Icon(icon, color: const Color(0xFF319F86)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}