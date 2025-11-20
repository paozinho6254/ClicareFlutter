import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/doctor_model.dart';
import '../doctor_schedule_screen.dart'; // A tela de agendamento que já temos!

class DoctorsByClinicScreen extends StatelessWidget {
  final String clinicId;
  final String clinicName;
  final String filterSpecialty;

  const DoctorsByClinicScreen({
    super.key,
    required this.clinicId,
    required this.clinicName,
    required this.filterSpecialty,
  });

  Future<List<DoctorModel>> _fetchDoctors() async {
    final response = await Supabase.instance.client
        .from('medicos')
        .select()
        .eq('clinica_id', clinicId)
        .eq('especialidade', filterSpecialty) // Aplica o filtro do funil
        .eq('ativo', true);

    return (response as List).map((e) => DoctorModel.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Médicos em $clinicName"),
        backgroundColor: const Color(0xFF00BFA6),
      ),
      body: FutureBuilder<List<DoctorModel>>(
        future: _fetchDoctors(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final doctors = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFF00BFA6).withOpacity(0.1),
                    child: Text(doctor.nome[0], style: const TextStyle(color: Color(0xFF00BFA6), fontWeight: FontWeight.bold)),
                  ),
                  title: Text(doctor.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("CRM: ${doctor.crm}"),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      // PASSO FINAL: TELA DE HORÁRIOS (Já existente)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorScheduleScreen(doctor: doctor),
                        ),
                      );
                    },
                    child: const Text("Ver Horários", style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}