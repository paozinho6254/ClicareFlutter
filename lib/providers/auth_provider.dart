import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserModel? _user;
  String? _token;
  bool _isLoading = true; // Começa carregando para tentar o auto-login

  UserModel? get user => _user;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    tryAutoLogin();
  }

  // Equivalente a verificar a sessão ao iniciar o app
  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'jwtToken');
    if (token == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final userProfile = await _apiService.getUserProfile(token);
      _user = userProfile;
      _token = token;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Se o token for inválido, desloga
      await logout();
    }
  }

  Future<void> login(String email, String password) async {
    final token = await _apiService.login(email, password);
    await _storage.write(key: 'jwtToken', value: token);
    await tryAutoLogin(); // Reutiliza a lógica para buscar o perfil
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    await _storage.delete(key: 'jwtToken');
    notifyListeners();
  }
}