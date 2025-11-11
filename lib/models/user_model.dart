class UserModel {
  final int id;
  final String nomeExibicao;
  final String email;
  final String tipoUsuario;

  UserModel({
    required this.id,
    required this.nomeExibicao,
    required this.email,
    required this.tipoUsuario,
  });

  // Construtor de fábrica para criar uma instância a partir de um JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nomeExibicao: json['nomeExibicao'],
      email: json['email'],
      tipoUsuario: json['tipoUsuario'],
    );
  }
}