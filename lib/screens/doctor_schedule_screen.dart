import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Adicione intl no pubspec.yaml para formatar datas
import '../models/doctor_model.dart';
import '../models/schedule_config_model.dart';

class DoctorScheduleScreen extends StatefulWidget {
  final DoctorModel doctor; // Recebe o médico selecionado

  const DoctorScheduleScreen({super.key, required this.doctor});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final _supabase = Supabase.instance.client;

  // Estado
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isLoadingSlots = false;
  List<TimeOfDay> _availableSlots = [];

  // Gera os próximos 14 dias para o carrossel horizontal
  late List<DateTime> _nextDays;

  @override
  void initState() {
    super.initState();
    // Gera lista de datas a partir de hoje
    _nextDays = List.generate(14, (index) => DateTime.now().add(Duration(days: index)));
    // Carrega slots para o dia atual (hoje)
    _fetchSlotsForDate(_selectedDate);
  }

  // --- LÓGICA PRINCIPAL: BARBEARIA ---
  Future<void> _fetchSlotsForDate(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _availableSlots = [];
      _selectedTime = null; // Reseta seleção anterior
      _selectedDate = date;
    });

    try {
      // 1. Busca a CONFIGURAÇÃO do médico para esse dia da semana
      // weekday no Dart: 1=Seg, 7=Dom. No nosso banco usamos essa mesma lógica.
      final configResponse = await _supabase
          .from('horarios_config')
          .select()
          .eq('medico_id', widget.doctor.id!)
          .eq('dia_semana', date.weekday)
          .maybeSingle();

      if (configResponse == null) {
        // Médico não atende neste dia da semana
        setState(() => _isLoadingSlots = false);
        return;
      }

      final config = ScheduleConfigModel.fromJson(configResponse);

      // 2. Busca AGENDAMENTOS JÁ FEITOS para esse médico nessa data específica
      // Filtra pelo dia inteiro (00:00 até 23:59)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final appointmentsResponse = await _supabase
          .from('agendamento')
          .select('data_consulta')
          .eq('id_medico', widget.doctor.id!)
          .gte('data_consulta', startOfDay.toIso8601String())
          .lt('data_consulta', endOfDay.toIso8601String());

      // Cria lista de horários ocupados
      final bookedTimes = (appointmentsResponse as List).map((e) {
        final dt = DateTime.parse(e['data_consulta']).toLocal();
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      }).toList();

      // 3. GERA OS SLOTS LIVRES
      List<TimeOfDay> slots = [];

      // Converte TimeOfDay para minutos para facilitar cálculo
      int currentMinutes = config.horaInicio.hour * 60 + config.horaInicio.minute;
      int endMinutes = config.horaFim.hour * 60 + config.horaFim.minute;

      while (currentMinutes + config.duracaoMinutos <= endMinutes) {
        final slotTime = TimeOfDay(hour: currentMinutes ~/ 60, minute: currentMinutes % 60);

        // Verifica se já está ocupado (compara Hora e Minuto)
        bool isBooked = bookedTimes.any((bt) => bt.hour == slotTime.hour && bt.minute == slotTime.minute);

        // Verifica se é passado (se for hoje)
        bool isPast = false;
        if (date.day == DateTime.now().day && date.month == DateTime.now().month) {
          final now = TimeOfDay.now();
          if (slotTime.hour < now.hour || (slotTime.hour == now.hour && slotTime.minute < now.minute)) {
            isPast = true;
          }
        }

        if (!isBooked && !isPast) {
          slots.add(slotTime);
        }

        currentMinutes += config.duracaoMinutos;
      }

      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
      });

    } catch (e) {
      print("Erro ao buscar slots: $e");
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _confirmAppointment() async {
    if (_selectedTime == null) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Não logado");

      // Cria o DateTime final combinando a data escolhida e a hora escolhida
      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await _supabase.from('agendamento').insert({
        'id_paciente': user.id,
        'id_medico': widget.doctor.id!,
        'clinica_id': widget.doctor.clinicaId,
        'data_consulta': finalDateTime.toIso8601String(),
        'status': 'Agendado',
        'valor_consulta': 150.00,
        'modalidade': 'Presencial'
      });

      if (mounted) {
        Navigator.pop(context); // Fecha modal
        Navigator.pop(context); // Sai da tela
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Consulta agendada com sucesso!'), backgroundColor: Color(0xFF1BAA9B))
        );
      }

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1BAA9B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FDFB),
      appBar: AppBar(
        title: Text(widget.doctor.nome),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- CABEÇALHO DO MÉDICO ---
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.person, size: 30, color: Color(0xFF1BAA9B))),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.doctor.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(widget.doctor.especialidade, style: const TextStyle(color: Colors.grey)),
                    Text("CRM: ${widget.doctor.crm}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --- SELETOR DE DATAS (Carrossel) ---
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _nextDays.length,
              itemBuilder: (context, index) {
                final date = _nextDays[index];
                final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;

                return GestureDetector(
                  onTap: () => _fetchSlotsForDate(date),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
                        boxShadow: [if(isSelected) BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0,4))]
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('EEE', 'pt_BR').format(date).toUpperCase(), // Ex: SEG
                            style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey)),
                        const SizedBox(height: 5),
                        Text(date.day.toString(),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(),

          // --- GRID DE HORÁRIOS ---
          Expanded(
            child: _isLoadingSlots
                ? const Center(child: CircularProgressIndicator())
                : _availableSlots.isEmpty
                ? const Center(child: Text("Nenhum horário disponível nesta data."))
                : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10
              ),
              itemCount: _availableSlots.length,
              itemBuilder: (context, index) {
                final time = _availableSlots[index];
                final isSelected = _selectedTime == time;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedTime = time);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      time.format(context),
                      style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- BOTÃO DE CONFIRMAÇÃO ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _selectedTime == null
                    ? null
                    : () => _showConfirmModal(context),
                child: const Text("Agendar Consulta", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Modal Simples
  void _showConfirmModal(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Confirmar Agendamento?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text("Médico: ${widget.doctor.nome}"),
              Text("Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}"),
              Text("Hora: ${_selectedTime!.format(context)}"),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmAppointment,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1BAA9B)),
                  child: const Text("CONFIRMAR", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        )
    );
  }
}