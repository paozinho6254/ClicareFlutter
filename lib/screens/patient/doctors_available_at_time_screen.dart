import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/doctor_model.dart';

class DoctorsAvailableAtTimeScreen extends StatefulWidget {
  final String clinicId;
  final String specialty;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;

  const DoctorsAvailableAtTimeScreen({
    super.key,
    required this.clinicId,
    required this.specialty,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  State<DoctorsAvailableAtTimeScreen> createState() => _DoctorsAvailableAtTimeScreenState();
}

class _DoctorsAvailableAtTimeScreenState extends State<DoctorsAvailableAtTimeScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<DoctorModel> _availableDoctors = [];

  @override
  void initState() {
    super.initState();
    _findDoctors();
  }

  Future<void> _findDoctors() async {
    try {
      // 1. Pega todos os médicos da especialidade/clínica
      final doctorsRes = await _supabase
          .from('medicos')
          .select()
          .eq('clinica_id', widget.clinicId)
          .eq('especialidade', widget.specialty)
          .eq('ativo', true);

      final allDoctors = (doctorsRes as List).map((e) => DoctorModel.fromJson(e)).toList();

      final List<DoctorModel> filtered = [];

      // 2. Para cada médico, verifica se ele realmente pode nesse horário
      // (Essa lógica é parecida com a anterior, mas agora filtrando um a um)
      for (var doc in allDoctors) {
        if (doc.id == null) continue;

        // Verifica Configuração
        final configRes = await _supabase
            .from('horarios_config')
            .select()
            .eq('medico_id', doc.id!)
            .eq('dia_semana', widget.selectedDate.weekday)
            .maybeSingle();

        if (configRes == null) continue; // Não trabalha nesse dia

        // Verifica se o horário clicado está dentro do range do médico
        // OBS: Precisaria checar também se bate com os minutos (slots de 30 min)
        // Para simplificar, assumimos que se está dentro do range e não tem booking, tá livre.

        // Verifica Agendamento Existente
        final bookingDateTime = DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            widget.selectedDate.day,
            widget.selectedTime.hour,
            widget.selectedTime.minute
        );

        final bookingRes = await _supabase
            .from('agendamento')
            .select('id_agendamento')
            .eq('id_medico', doc.id!)
            .eq('data_consulta', bookingDateTime.toIso8601String())
            .maybeSingle();

        if (bookingRes == null) {
          filtered.add(doc);
        }
      }

      setState(() {
        _availableDoctors = filtered;
        _isLoading = false;
      });

    } catch (e) {
      print("Erro ao filtrar médicos: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmBooking(DoctorModel doctor) async {
    try {
      final user = _supabase.auth.currentUser;

      final finalDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        widget.selectedTime.hour,
        widget.selectedTime.minute,
      );

      await _supabase.from('agendamento').insert({
        'id_paciente': user!.id,
        'id_medico': doctor.id!,
        'clinica_id': widget.clinicId,
        'data_consulta': finalDateTime.toIso8601String(),
        'status': 'Agendado',
        'modalidade': 'Presencial',
        'valor_consulta': 200.00 // Exemplo
      });

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst); // Volta pra Home
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Consulta Confirmada!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Médicos às ${widget.selectedTime.format(context)}"),
        backgroundColor: const Color(0xFF00BFA6),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableDoctors.isEmpty
          ? const Center(child: Text("Ops! Esse horário acabou de ser ocupado."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableDoctors.length,
        itemBuilder: (context, index) {
          final doctor = _availableDoctors[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE0F2F1),
                child: Text(doctor.nome[0]),
              ),
              title: Text(doctor.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("CRM: ${doctor.crm}"),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA6)),
                onPressed: () => _confirmBooking(doctor),
                child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }
}