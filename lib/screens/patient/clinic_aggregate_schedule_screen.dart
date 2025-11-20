import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/schedule_config_model.dart';
import 'doctors_available_at_time_screen.dart'; // Vamos criar no Passo 3

class ClinicAggregateScheduleScreen extends StatefulWidget {
  final String clinicId;
  final String clinicName;
  final String specialty;

  const ClinicAggregateScheduleScreen({
    super.key,
    required this.clinicId,
    required this.clinicName,
    required this.specialty,
  });

  @override
  State<ClinicAggregateScheduleScreen> createState() => _ClinicAggregateScheduleScreenState();
}

class _ClinicAggregateScheduleScreenState extends State<ClinicAggregateScheduleScreen> {
  final _supabase = Supabase.instance.client;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<TimeOfDay> _aggregatedSlots = []; // Lista de horários únicos disponíveis na clínica
  late List<DateTime> _nextDays;

  @override
  void initState() {
    super.initState();
    _nextDays = List.generate(14, (index) => DateTime.now().add(Duration(days: index)));
    _fetchAggregatedSlots(_selectedDate);
  }

  Future<void> _fetchAggregatedSlots(DateTime date) async {
    setState(() {
      _isLoading = true;
      _selectedDate = date;
      _aggregatedSlots = [];
    });

    try {
      // 1. Buscar TODOS os médicos dessa clínica com essa especialidade
      final doctorsRes = await _supabase
          .from('medicos')
          .select('id')
          .eq('clinica_id', widget.clinicId)
          .eq('especialidade', widget.specialty)
          .eq('ativo', true);

      final doctorIds = (doctorsRes as List).map((e) => e['id'] as int).toList();

      if (doctorIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Buscar configurações de horário desses médicos para o dia da semana
      final configsRes = await _supabase
          .from('horarios_config')
          .select()
          .filter('medico_id', 'in', doctorIds)
          .eq('dia_semana', date.weekday);

      // 3. Buscar agendamentos já feitos para esses médicos nesta data
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final bookingsRes = await _supabase
          .from('agendamento')
          .select('data_consulta, id_medico')
          .filter('id_medico', 'in', doctorIds)
          .gte('data_consulta', startOfDay.toIso8601String())
          .lt('data_consulta', endOfDay.toIso8601String());

      // Transforma agendamentos em um Mapa fácil de consultar: "ID_MEDICO -> Lista de Horarios Ocupados"
      final Map<int, List<TimeOfDay>> busySlotsByDoctor = {};
      for (var b in bookingsRes as List) {
        final mId = b['id_medico'] as int; // ou String se mudou no banco, mas no seu SQL era ID numérico na tab medicos? Verifique.
        // NOTA: Se no passo anterior mudamos o ID do médico para UUID ou Int, ajuste aqui.
        // Vou assumir que o ID da tabela 'medicos' é BIGINT (int no Dart).

        final dt = DateTime.parse(b['data_consulta']).toLocal();
        final time = TimeOfDay(hour: dt.hour, minute: dt.minute);

        if (!busySlotsByDoctor.containsKey(mId)) busySlotsByDoctor[mId] = [];
        busySlotsByDoctor[mId]!.add(time);
      }

      // 4. Calcular slots e fazer o Merge (União)
      final Set<TimeOfDay> uniqueSlots = {}; // Set evita duplicatas (ex: 10:00 só aparece uma vez)

      for (var configMap in configsRes as List) {
        final config = ScheduleConfigModel.fromJson(configMap);
        final medicoId = configMap['medico_id']; // Precisamos saber de quem é esse config

        int currentMinutes = config.horaInicio.hour * 60 + config.horaInicio.minute;
        int endMinutes = config.horaFim.hour * 60 + config.horaFim.minute;

        while (currentMinutes + config.duracaoMinutos <= endMinutes) {
          final slotTime = TimeOfDay(hour: currentMinutes ~/ 60, minute: currentMinutes % 60);

          // Verifica se ESSE médico está ocupado nesse horário
          bool isBooked = false;
          if (busySlotsByDoctor.containsKey(medicoId)) {
            isBooked = busySlotsByDoctor[medicoId]!.any((t) => t.hour == slotTime.hour && t.minute == slotTime.minute);
          }

          // Verifica passado
          bool isPast = false;
          if (date.day == DateTime.now().day && date.month == DateTime.now().month) {
            final now = TimeOfDay.now();
            if (slotTime.hour < now.hour || (slotTime.hour == now.hour && slotTime.minute < now.minute)) isPast = true;
          }

          if (!isBooked && !isPast) {
            uniqueSlots.add(slotTime);
          }
          currentMinutes += config.duracaoMinutos;
        }
      }

      // Ordenar os horários
      final sortedSlots = uniqueSlots.toList()
        ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

      setState(() {
        _aggregatedSlots = sortedSlots;
        _isLoading = false;
      });

    } catch (e) {
      print("Erro ao agregar horários: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Escolha o Horário", style: TextStyle(fontSize: 16)),
            Text(widget.clinicName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
          ],
        ),
        backgroundColor: const Color(0xFF00BFA6),
      ),
      body: Column(
        children: [
          // Calendário Horizontal
          Container(
            height: 90,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemCount: _nextDays.length,
              itemBuilder: (context, index) {
                final date = _nextDays[index];
                final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
                return GestureDetector(
                  onTap: () => _fetchAggregatedSlots(date),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00BFA6) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('EEE', 'pt_BR').format(date).toUpperCase(), style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.grey)),
                        Text(date.day.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Grid de Horários
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _aggregatedSlots.isEmpty
                ? const Center(child: Text("Nenhum horário disponível."))
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _aggregatedSlots.length,
              itemBuilder: (context, index) {
                final time = _aggregatedSlots[index];
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00BFA6),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFF00BFA6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // PRÓXIMO PASSO: Escolher qual médico vai atender nesse horário
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorsAvailableAtTimeScreen(
                          clinicId: widget.clinicId,
                          specialty: widget.specialty,
                          selectedDate: _selectedDate,
                          selectedTime: time,
                        ),
                      ),
                    );
                  },
                  child: Text(time.format(context)),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}