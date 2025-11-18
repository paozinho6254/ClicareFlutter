enum UserType { admin, patient, clinic, unknown }

class UserModel {
  final String id; // ID do Supabase geralmente é String (UUID)
  final String nomeExibicao;
  final String email;
  final UserType role; // Alterado de String para Enum

  UserModel({
    required this.id,
    required this.nomeExibicao,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nomeExibicao: json['nome'] ?? 'Usuário', // Ajuste conforme sua tabela
      email: json['email'],
      // Converte a string do banco para o Enum
      role: _parseUserType(json['tipo_usuario']),
    );
  }

  // Função auxiliar para converter String em Enum
  static UserType _parseUserType(String? type) {
    // Converte para minúsculo e remove espaços antes de verificar
    final normalizedType = type?.toLowerCase().trim();

    switch (normalizedType) {
      case 'admin':
        return UserType.admin;
      case 'paciente':
        return UserType.patient;
    // Aceita 'clinica' (portugues) ou 'clinic' (ingles)
      case 'clinica':
      case 'clinic':
        return UserType.clinic;
      default:
        print("AVISO: Tipo de usuário desconhecido recebido do banco: '$type'");
        return UserType.unknown;
    }
  }
}