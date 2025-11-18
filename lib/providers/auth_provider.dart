import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  supabase.User? _authUser;
  UserModel? _userProfile;
  bool _isLoading = true;

  UserModel? get userProfile => _userProfile;
  bool get isLoggedIn => _authUser != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final supabase.Session? session = data.session;
      _authUser = session?.user;

      if (_authUser != null) {
        // Se logou, busca os dados na tabela pública 'usuarios'
        _fetchUserProfile(_authUser!.id);
      } else {
        _userProfile = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  // --- BUSCAR DADOS DO USUÁRIO ---
  Future<void> _fetchUserProfile(String userId) async {
    try {
      // CORREÇÃO: Busca na tabela 'usuarios' que criamos no SQL
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('id_usuario', userId)
          .single();

      _userProfile = UserModel.fromJson(response);
    } catch (e) {
      print('Erro ao buscar perfil: $e');
      // Se der erro (ex: usuário criado no Auth mas sem linha na tabela usuarios),
      // podemos optar por não deslogar imediatamente ou tratar o erro.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- LOGIN ---
  Future<void> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _authUser = null;
    _userProfile = null;
    notifyListeners();
  }

  // --- REGISTRO DE PACIENTE (Lógica em Cascata) ---
  Future<void> registerPatient({
    required String email,
    required String password,
    required String nome,
    required String cpf,
    required String dataNascimento,
    required String telefone,
  }) async {
    try {
      // 1. Cria o usuário no Supabase Auth (Authentication)
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) throw Exception('Falha na autenticação');
      final String userId = authResponse.user!.id;

      // 2. Insere na tabela Pai (public.usuarios)
      await _supabase.from('usuarios').insert({
        'id_usuario': userId,
        'nome_usuario': nome,
        'email': email,
        'tipo_usuario': 'paciente',
        'ativo': true,
      });

      // 3. Insere na tabela Filha (public.paciente)
      // Primeiro precisamos criar um endereço fictício ou pedir no form.
      // Para simplificar agora, vamos criar o paciente sem endereço ou passar null se o banco permitir
      await _supabase.from('paciente').insert({
        'id_paciente': userId,
        'cpf_paciente': cpf,
        'data_nascimento_paciente': dataNascimento,
        'telefone_paciente': telefone,
        // 'id_endereco': null // Se o banco permitir null
      });

      // Atualiza o perfil localmente para evitar delay
      await _fetchUserProfile(userId);

    } catch (e) {
      // DICA DE OURO: Se falhar no passo 2 ou 3, o usuário ficou criado no Auth mas sem dados.
      // Em apps reais, você deletaria o usuário do Auth aqui para limpar a sujeira.
      print("Erro no registro: $e");
      rethrow;
    }
  }

  // --- REGISTRO DE CLÍNICA ---
  Future<void> registerClinic({
    required String email,
    required String password,
    required String nome,
    required String cnpj,
    required String telefone,
  }) async {
    try {
      // 1. Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) throw Exception('Falha na autenticação');
      final String userId = authResponse.user!.id;

      // 2. Tabela Usuarios
      await _supabase.from('usuarios').insert({
        'id_usuario': userId,
        'nome_usuario': nome,
        'email': email,
        'tipo_usuario': 'clinica',
        'ativo': true,
      });

      // 3. Tabela Clinica
      await _supabase.from('clinica').insert({
        'id_clinica': userId,
        'cnpj_clinica': cnpj,
        'telefone_clinica': telefone,
      });

      await _fetchUserProfile(userId);

    } catch (e) {
      rethrow;
    }
  }
}