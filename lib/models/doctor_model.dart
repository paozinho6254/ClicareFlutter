class DoctorModel {
  final int? id; // Pode ser nulo antes de salvar
  final String nome;
  final String especialidade;
  final String crm;

  DoctorModel({this.id, required this.nome, required this.especialidade, required this.crm});

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'],
      nome: json['nome'],
      especialidade: json['especialidade'],
      crm: json['crm'] ?? '',
    );
  }
}
