import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../screens/patient/appointment_list_screen.dart';

class NextAppointmentCard extends StatefulWidget {
  const NextAppointmentCard({super.key});

  @override
  State<NextAppointmentCard> createState() => _NextAppointmentCardState();
}

class _NextAppointmentCardState extends State<NextAppointmentCard> {
  final _supabase = Supabase.instance.client;

  // Stream que escuta agendamentos em tempo real, mas aqui usaremos Future
  // para facilitar o Join complexo. Para atualizar, puxe a tela (RefreshIndicator) na Home.
  Future<Map<String, dynamic>?> _fetchNextAppointment() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final now = DateTime.now().toIso8601String();

    // Busca o agendamento futuro mais próximo
    final response = await _supabase
        .from('agendamento')
        .select('data_consulta, modalidade, medicos(nome, especialidade)')
        .eq('id_paciente', userId)
        .gte('data_consulta', now) // Apenas datas futuras
        .order('data_consulta', ascending: true) // O mais próximo primeiro
        .limit(1)
        .maybeSingle(); // Retorna null se não tiver nada, ou o objeto se tiver

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchNextAppointment(),
      builder: (context, snapshot) {
        // 1. Carregando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        // 2. Sem agendamentos futuros
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildEmptyCard();
        }

        // 3. Tem agendamento
        final data = snapshot.data!;
        final medico = data['medicos']; // Vem do JOIN
        final dataConsulta = DateTime.parse(data['data_consulta']).toLocal();
        final modalidade = data['modalidade'] ?? 'Presencial';

        // Formatação
        final nomeMedico = medico != null ? medico['nome'] : 'Médico';
        final especialidade = medico != null ? medico['especialidade'] : 'Clínica Geral';
        final dataFormatada = DateFormat("EEE, d 'de' MMM • HH:mm", 'pt_BR').format(dataConsulta);

        // Ícone baseado na modalidade
        final isVideo = modalidade.toString().toLowerCase().contains('tele');
        final icon = isVideo ? Icons.videocam : Icons.person;
        final labelModalidade = isVideo ? "Telemedicina" : "Presencial";

        return GestureDetector(
          onTap: () {
            // Leva para a lista completa ao clicar
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsListScreen()));
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA6),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BFA6).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nomeMedico,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  especialidade,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      labelModalidade,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dataFormatada, // Ex: Seg, 25 de Nov • 14:30
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, // Card branco para destacar que está vazio
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: const [
          Icon(Icons.event_available, color: Colors.grey, size: 40),
          SizedBox(height: 10),
          Text("Nenhuma consulta agendada.", style: TextStyle(color: Colors.grey)),
          Text("Que tal marcar uma agora?", style: TextStyle(color: Color(0xFF00BFA6), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA6))),
    );
  }
}