import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'clinic_aggregate_schedule_screen.dart';
import 'doctors_by_clinic_screen.dart'; // Vamos criar no Passo 3

class ClinicsResultScreen extends StatefulWidget {
  final String specialty; // Recebe "Cardiologia"

  const ClinicsResultScreen({super.key, required this.specialty});

  @override
  State<ClinicsResultScreen> createState() => _ClinicsResultScreenState();
}

class _ClinicsResultScreenState extends State<ClinicsResultScreen> {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchClinicsWithSpecialty() async {
    // 1. Encontra médicos com essa especialidade
    final doctorsResponse = await _supabase
        .from('medicos')
        .select('clinica_id')
        .eq('especialidade', widget.specialty)
        .eq('ativo', true);

    if ((doctorsResponse as List).isEmpty) return [];

    // Cria uma lista de IDs únicos de clínicas
    final clinicIds = doctorsResponse.map((e) => e['clinica_id']).toSet().toList();

    // ⚠️ SEGURANÇA: O operador 'in' pode dar erro se a lista estiver vazia.
    if (clinicIds.isEmpty) return [];

    // 2. Busca os detalhes dessas clínicas
    final clinicsResponse = await _supabase
        .from('clinica')
        .select('*, usuarios(nome_usuario)')
    // --- MUDANÇA AQUI ---
    // Em vez de .in_(), usamos .filter()
    // Sintaxe: .filter('coluna', 'operador', valor)
        .filter('id_clinica', 'in', clinicIds);

    return List<Map<String, dynamic>>.from(clinicsResponse);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Clínicas de ${widget.specialty}"),
        backgroundColor: const Color(0xFF00BFA6),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchClinicsWithSpecialty(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final clinics = snapshot.data!;

          if (clinics.isEmpty) {
            return const Center(child: Text("Nenhuma clínica encontrada."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clinics.length,
            itemBuilder: (context, index) {
              final clinicData = clinics[index];
              final userData = clinicData['usuarios'] ?? {};
              final nomeClinica = userData['nome_usuario'] ?? 'Clínica sem nome';
              final telefone = clinicData['telefone_clinica'];
              final clinicId = clinicData['id_clinica'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2F1),
                    child: Icon(Icons.local_hospital, color: Color(0xFF00BFA6)),
                  ),
                  title: Text(nomeClinica, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Tel: $telefone"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // MUDANÇA: Vai para a seleção de DATA/HORA primeiro
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClinicAggregateScheduleScreen(
                          clinicId: clinicId,
                          clinicName: nomeClinica,
                          specialty: widget.specialty, // Passa a especialidade escolhida
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}