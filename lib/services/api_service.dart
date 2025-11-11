import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class ApiService {
  // --- Equivalente ao PacienteService.cadastrar ---
  Future<PatientModel> registerPatient(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/pacientes/cadastrar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return PatientModel.fromJson(jsonDecode(response.body));
    } else {
      // Lança um erro com a mensagem do backend
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Falha ao cadastrar paciente');
    }
  }

  // --- Equivalente ao AuthController.login ---
  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['token'];
    } else {
      throw Exception('Falha ao fazer login: Credenciais inválidas');
    }
  }

  // --- Equivalente ao AuthController.getAuthenticatedUser ---
  Future<UserModel> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao buscar perfil do usuário: Sessão inválida');
    }
  }

  Future<void> registerClinic(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/clinicas/cadastrar'), // Endpoint de cadastro da clínica
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    // O backend deve retornar 201 Created em caso de sucesso
    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Falha ao cadastrar clínica');
    }
    // Não precisa retornar nada em caso de sucesso
  }
}