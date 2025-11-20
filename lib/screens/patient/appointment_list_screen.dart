import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AppointmentsListScreen extends StatelessWidget {
  const AppointmentsListScreen({super.key});

  Stream<List<Map<String, dynamic>>> _getMyAppointments() {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return Supabase.instance.client
        .from('agendamento')
        .stream(primaryKey: ['id_agendamento'])
        .eq('id_paciente', userId)
        .order('data_consulta', ascending: true) // Próximas primeiro
        .map((data) => data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F9),
      appBar: AppBar(
        title: const Text("Minhas Consultas", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getMyAppointments(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final appointments = snapshot.data!;

          if (appointments.isEmpty) {
            return const Center(child: Text("Você ainda não tem consultas agendadas."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final apt = appointments[index];
              final date = DateTime.parse(apt['data_consulta']).toLocal();
              final isPast = date.isBefore(DateTime.now());

              // Nota: Para pegar o nome do médico, o ideal seria um 'join' na query
              // ou buscar o nome separado. Para simplificar aqui, vamos focar na data.

              return _appointmentCard(
                // Aqui você precisaria fazer um join no Supabase para pegar o nome do médico
                // Por enquanto vamos colocar um placeholder ou ID
                  doctorName: "Médico (ID: ${apt['id_medico']})",
                  specialty: apt['modalidade'] ?? 'Geral',
                  date: DateFormat('dd/MM • HH:mm').format(date),
                  status: apt['status'] ?? 'Agendado',
                  past: isPast
              );
            },
          );
        },
      ),
    );
  }

  Widget _appointmentCard({
    required String doctorName,
    required String specialty,
    required String date,
    required String status,
    bool past = false
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: past ? Colors.white : const Color(0xFF00BFA6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [if(past) const BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                doctorName,
                style: TextStyle(color: past ? Colors.black : Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8)
                ),
                child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10)),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text(
            specialty,
            style: TextStyle(color: past ? Colors.black54 : Colors.white70),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: past ? Colors.black87 : Colors.white),
              const SizedBox(width: 5),
              Text(
                date,
                style: TextStyle(color: past ? Colors.black87 : Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}