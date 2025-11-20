import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
// 1. IMPORT NECESSÁRIO PARA CORRIGIR O ERRO DE DATA
import 'package:intl/date_symbol_data_local.dart';

import '../../models/schedule_config_model.dart';
import 'doctors_available_at_time_screen.dart';

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
  bool _isLoading = true; // Começa carregando
  List<TimeOfDay> _aggregatedSlots = [];

  // Inicializa vazia para não dar erro antes de carregar o idioma
  List<DateTime> _nextDays = [];

  @override
  void initState() {
    super.initState();

    // 2. CORREÇÃO: Inicializa o idioma ANTES de gerar as datas
    initializeDateFormatting('pt_BR', null).then((_) {
      if (mounted) {
        setState(() {
          _nextDays = List.generate(14, (index) => DateTime.now().add(Duration(days: index)));
          // Agora que temos datas e idioma, buscamos os horários
          _fetchAggregatedSlots(_selectedDate);
        });
      }
    });
  }

  // --- A FUNÇÃO QUE ESTAVA FALTANDO ---
  Future<void> _fetchAggregatedSlots(DateTime date) async {
    setState(() {
      _isLoading = true;
      _selectedDate = date;
      _aggregatedSlots = [];
    });

    try {
      print("\n=== INICIO DO DEBUG DE HORÁRIOS ===");
      print("1. Buscando para Data: $date (Dia da semana: ${date.weekday})");
      print("   Clínica: ${widget.clinicId} | Especialidade: ${widget.specialty}");

      // A. Buscar Médicos
      final doctorsRes = await _supabase
          .from('medicos')
          .select('id, nome')
          .eq('clinica_id', widget.clinicId)
          .eq('especialidade', widget.specialty)
          .eq('ativo', true);

      print("2. Médicos encontrados: $doctorsRes");

      final doctorIds = (doctorsRes as List).map((e) => e['id'] as int).toList();

      if (doctorIds.isEmpty) {
        print(">>> AVISO: Nenhum médico encontrado. Verifique se a especialidade está escrita EXATAMENTE igual.");
        setState(() => _isLoading = false);
        return;
      }

      // B. Buscar Configurações (Regras)
      final configsRes = await _supabase
          .from('horarios_config')
          .select()
          .filter('medico_id', 'in', doctorIds)
          .eq('dia_semana', date.weekday);

      print("3. Configurações (Regras) encontradas: ${configsRes.length}");
      if (configsRes.isEmpty) {
        print(">>> AVISO: Médicos existem, mas NENHUM tem horário configurado para o dia da semana ${date.weekday}.");
      }

      // C. Buscar Agendamentos (Ocupados)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final bookingsRes = await _supabase
          .from('agendamento')
          .select('data_consulta, id_medico')
          .filter('id_medico', 'in', doctorIds)
          .gte('data_consulta', startOfDay.toIso8601String())
          .lt('data_consulta', endOfDay.toIso8601String());

      print("4. Agendamentos (Ocupados) hoje: ${bookingsRes.length}");

      // Mapeia ocupados
      final Map<int, List<TimeOfDay>> busySlotsByDoctor = {};
      for (var b in bookingsRes as List) {
        final mId = b['id_medico'] as int;
        final dt = DateTime.parse(b['data_consulta']).toLocal();
        final time = TimeOfDay(hour: dt.hour, minute: dt.minute);
        if (!busySlotsByDoctor.containsKey(mId)) busySlotsByDoctor[mId] = [];
        busySlotsByDoctor[mId]!.add(time);
      }

      // D. Calcular Slots
      final Set<TimeOfDay> uniqueSlots = {};

      for (var configMap in configsRes as List) {
        final medicoId = configMap['medico_id'];
        print("   -> Processando regra para médico ID: $medicoId");

        // Converte strings "08:00:00" para TimeOfDay
        final inicioStr = configMap['hora_inicio'].toString().split(':');
        final fimStr = configMap['hora_fim'].toString().split(':');

        final horaInicio = TimeOfDay(hour: int.parse(inicioStr[0]), minute: int.parse(inicioStr[1]));
        final horaFim = TimeOfDay(hour: int.parse(fimStr[0]), minute: int.parse(fimStr[1]));

        // Garante duração
        int duration = configMap['duracao_consulta_minutos'] ?? 30;
        if (duration <= 0) duration = 30;

        print("      Regra: ${horaInicio.format(context)} até ${horaFim.format(context)} (Blocos de $duration min)");

        // Loop matemático
        int currentMinutes = horaInicio.hour * 60 + horaInicio.minute;
        int endMinutes = horaFim.hour * 60 + horaFim.minute;

        while (currentMinutes + duration <= endMinutes) {
          final slotTime = TimeOfDay(hour: currentMinutes ~/ 60, minute: currentMinutes % 60);

          // Verifica Ocupado
          bool isBooked = false;
          if (busySlotsByDoctor.containsKey(medicoId)) {
            isBooked = busySlotsByDoctor[medicoId]!.any((t) => t.hour == slotTime.hour && t.minute == slotTime.minute);
          }

          // Verifica Passado (Só se for hoje)
          bool isPast = false;
          if (date.day == DateTime.now().day && date.month == DateTime.now().month) {
            final now = TimeOfDay.now();
            // Compara minutos totais para precisão
            final nowMin = now.hour * 60 + now.minute;
            final slotMin = slotTime.hour * 60 + slotTime.minute;
            if (slotMin < nowMin) isPast = true;
          }

          if (isBooked) {
            print("      [X] ${slotTime.format(context)} - Ocupado");
          } else if (isPast) {
            print("      [X] ${slotTime.format(context)} - Já passou");
          } else {
            print("      [OK] ${slotTime.format(context)} - Disponível!");
            uniqueSlots.add(slotTime);
          }

          currentMinutes += duration;
        }
      }

      // Ordenar
      final sortedSlots = uniqueSlots.toList()
        ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

      print("=== FIM DO DEBUG: Total de slots gerados: ${sortedSlots.length} ===");

      setState(() {
        _aggregatedSlots = sortedSlots;
        _isLoading = false;
      });

    } catch (e, stackTrace) {
      print("ERRO CRÍTICO AO BUSCAR HORÁRIOS: $e");
      print(stackTrace);
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
      body: _nextDays.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Proteção enquanto carrega data
          : Column(
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