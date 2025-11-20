import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'clinic_result_screen.dart'; // Vamos criar no Passo 2

class SpecialtySelectionScreen extends StatefulWidget {
  const SpecialtySelectionScreen({super.key});

  @override
  State<SpecialtySelectionScreen> createState() => _SpecialtySelectionScreenState();
}

class _SpecialtySelectionScreenState extends State<SpecialtySelectionScreen> {
  final _supabase = Supabase.instance.client;

  // Função para buscar especialidades únicas
  Future<List<String>> _fetchSpecialties() async {
    // Busca apenas a coluna 'especialidade' de todos os médicos ativos
    final response = await _supabase
        .from('medicos')
        .select('especialidade')
        .eq('ativo', true);

    final List<dynamic> data = response as List;

    // Transforma em Set para remover duplicatas e volta para List
    final uniqueSpecialties = data
        .map((e) => e['especialidade'] as String)
        .toSet()
        .toList();

    uniqueSpecialties.sort(); // Ordena alfabeticamente
    return uniqueSpecialties;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Qual especialidade precisa?"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<String>>(
        future: _fetchSpecialties(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final specialties = snapshot.data!;

          if (specialties.isEmpty) {
            return const Center(child: Text("Nenhuma especialidade encontrada."));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: specialties.length,
            itemBuilder: (context, index) {
              final spec = specialties[index];
              return _buildSpecialtyCard(context, spec);
            },
          );
        },
      ),
    );
  }

  Widget _buildSpecialtyCard(BuildContext context, String specialty) {
    // Mapeamento simples de ícones (opcional)
    IconData icon = Icons.medical_services;
    if (specialty.toLowerCase().contains('cardio')) icon = Icons.favorite;
    if (specialty.toLowerCase().contains('dermo')) icon = Icons.face;
    if (specialty.toLowerCase().contains('olho') || specialty.contains('Oftalmo')) icon = Icons.visibility;

    return GestureDetector(
      onTap: () {
        // NAVEGAÇÃO PARA O PRÓXIMO PASSO: ESCOLHER CLÍNICA
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClinicsResultScreen(specialty: specialty),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
          border: Border.all(color: const Color(0xFF00BFA6).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF00BFA6)),
            const SizedBox(height: 10),
            Text(
              specialty,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}