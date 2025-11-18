import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/doctor_model.dart';
import 'manage_doctor_screen.dart'; // Vamos criar abaixo

class MyDoctorsScreen extends StatefulWidget {
  const MyDoctorsScreen({super.key});

  @override
  State<MyDoctorsScreen> createState() => _MyDoctorsScreenState();
}

class _MyDoctorsScreenState extends State<MyDoctorsScreen> {
  final _supabase = Supabase.instance.client;

  // Stream que ouve mudanças na tabela de médicos em tempo real
  Stream<List<DoctorModel>> _getDoctorsStream() {
    return _supabase
        .from('medicos')
        .stream(primaryKey: ['id'])
        .eq('clinica_id', _supabase.auth.currentUser!.id)
        .map((data) => data.map((e) => DoctorModel.fromJson(e)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Médicos'), backgroundColor: const Color(0xFF319F86)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF319F86),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // Abre tela de criação (sem médico passado por parâmetro)
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageDoctorScreen()));
        },
      ),
      body: StreamBuilder<List<DoctorModel>>(
        stream: _getDoctorsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final doctors = snapshot.data!;

          if (doctors.isEmpty) {
            return const Center(child: Text('Nenhum médico cadastrado.'));
          }

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF319F86).withOpacity(0.2),
                    child: Text(doctor.nome[0], style: const TextStyle(color: Color(0xFF319F86))),
                  ),
                  title: Text(doctor.nome),
                  subtitle: Text('${doctor.especialidade} | CRM: ${doctor.crm}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Abre tela de edição (passando o médico)
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ManageDoctorScreen(doctor: doctor)));
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