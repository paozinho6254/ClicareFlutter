import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/doctor_model.dart';
import '../doctor_schedule_screen.dart'; // Importe a tela de horários

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final _supabase = Supabase.instance.client;

  // Variável para o campo de busca
  String _searchQuery = '';

  // Stream que busca médicos (filtra por nome se tiver busca)
  Stream<List<DoctorModel>> _getDoctorsStream() {
    var query = _supabase
        .from('medicos')
        .stream(primaryKey: ['id'])
        .order('nome', ascending: true);

    // Nota: O .stream() do Supabase tem limitações para filtros dinâmicos complexos (ILike).
    // Para uma busca simples local, faremos o filtro no .map abaixo.

    return query.map((data) {
      final doctors = data.map((e) => DoctorModel.fromJson(e)).toList();

      if (_searchQuery.isEmpty) {
        return doctors;
      } else {
        return doctors.where((doc) =>
        doc.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            doc.especialidade.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encontrar Especialista', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Nome do médico ou especialidade...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),

          // Lista de Médicos
          Expanded(
            child: StreamBuilder<List<DoctorModel>>(
              stream: _getDoctorsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final doctors = snapshot.data!;

                if (doctors.isEmpty) {
                  return const Center(child: Text('Nenhum médico encontrado.'));
                }

                return ListView.builder(
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF00BFA6).withOpacity(0.1),
                          child: Text(
                            doctor.nome[0],
                            style: const TextStyle(color: Color(0xFF00BFA6), fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                        title: Text(doctor.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doctor.especialidade, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            // Label indicando disponibilidade (Visual apenas)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4)
                              ),
                              child: const Text("Disponível", style: TextStyle(fontSize: 10, color: Colors.green)),
                            )
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          // --- AQUI ESTÁ A NAVEGAÇÃO FINAL ---
                          // Vai para a tela de horários desse médico específico
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorScheduleScreen(doctor: doctor),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}