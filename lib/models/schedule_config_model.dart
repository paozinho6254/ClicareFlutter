import 'package:flutter/material.dart';

class ScheduleConfigModel {
  final int? id;
  final int diaSemana; // 1 = Segunda, 7 = Domingo
  final TimeOfDay horaInicio;
  final TimeOfDay horaFim;
  final int duracaoMinutos;

  ScheduleConfigModel({
    this.id,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFim,
    this.duracaoMinutos = 30,
  });

  // Auxiliares para conversão TimeOfDay <-> String (HH:mm:ss)
  static TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTime(TimeOfDay time) {
    // Formata para HH:mm:00 para o Postgres
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  factory ScheduleConfigModel.fromJson(Map<String, dynamic> json) {
    return ScheduleConfigModel(
      id: json['id'],
      diaSemana: json['dia_semana'],
      horaInicio: _parseTime(json['hora_inicio']),
      horaFim: _parseTime(json['hora_fim']),
      duracaoMinutos: json['duracao_consulta_minutos'],
    );
  }

  Map<String, dynamic> toSupabase(int medicoId) {
    return {
      'medico_id': medicoId,
      'dia_semana': diaSemana,
      'hora_inicio': _formatTime(horaInicio),
      'hora_fim': _formatTime(horaFim),
      'duracao_consulta_minutos': duracaoMinutos,
    };
  }
}