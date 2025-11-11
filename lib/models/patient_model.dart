class PatientModel {
  final int id;
  final String nome;
  final String email;
  final String cpf;
  final String dataNascimento;

  PatientModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.dataNascimento,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      cpf: json['cpf'],
      dataNascimento: json['dataNascimento'],
    );
  }
}