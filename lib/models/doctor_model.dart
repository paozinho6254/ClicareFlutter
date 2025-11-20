class DoctorModel {
  final int? id;
  final String clinicaId; // <--- NOVO CAMPO OBRIGATÓRIO
  final String nome;
  final String especialidade;
  final String crm;

  DoctorModel({
    this.id,
    required this.clinicaId, // <--- Adicionado no construtor
    required this.nome,
    required this.especialidade,
    required this.crm,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'], // O id vem como int do banco
      clinicaId: json['clinica_id'] ?? '', // <--- Mapeia do banco (snake_case) para o Dart (camelCase)
      nome: json['nome'] ?? 'Sem Nome',
      especialidade: json['especialidade'] ?? 'Geral',
      crm: json['crm'] ?? '',
    );
  }

  // Opcional: Para facilitar o envio de volta ao banco se precisar
  Map<String, dynamic> toJson() {
    return {
      'clinica_id': clinicaId,
      'nome': nome,
      'especialidade': especialidade,
      'crm': crm,
      // não enviamos o ID aqui pois o banco gera automático
    };
  }
}