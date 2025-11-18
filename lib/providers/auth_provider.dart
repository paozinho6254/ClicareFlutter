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
      print("Buscando perfil para o ID: $userId"); // DEBUG

      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('id_usuario', userId)
          .maybeSingle(); // <--- Mudei de .single() para .maybeSingle()

      if (response == null) {
        print("ERRO CRÍTICO: Usuário autenticado, mas sem perfil na tabela 'usuarios'!");
        // Opcional: Forçar logout se não tiver perfil para evitar tela branca
        // await logout();
        return;
      }

      print("Perfil encontrado: $response"); // DEBUG
      _userProfile = UserModel.fromJson(response);

    } catch (e) {
      print('EXCEÇÃO ao buscar perfil: $e');
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
      // 1. Criar Autenticação
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) throw Exception('Falha na autenticação');
      final String userId = authResponse.user!.id;

      print("Usuário Auth criado: $userId. Tentando inserir no banco...");

      // 2. Inserir na tabela USUARIOS
      // ATENÇÃO: As chaves aqui DEVEM ser iguais às colunas do Supabase
      await _supabase.from('usuarios').insert({
        'id_usuario': userId,
        'nome_usuario': nome, // Verifique se no banco é 'nome' ou 'nome_usuario'
        'email': email,
        'tipo_usuario': 'clinica', // Minúsculo
        'ativo': true,
      });

      print("Tabela 'usuarios' inserida com sucesso.");

      // 3. Inserir na tabela CLINICA
      await _supabase.from('clinica').insert({
        'id_clinica': userId,
        'cnpj_clinica': cnpj,
        'telefone_clinica': telefone,
      });

      print("Tabela 'clinica' inserida com sucesso.");

      // 4. FORÇAR ATUALIZAÇÃO DO PERFIL
      // Como o insert acabou de acontecer, agora é seguro buscar os dados.
      await _fetchUserProfile(userId);

    } catch (e) {
      print("ERRO NO REGISTRO: $e");
      // Se der erro no banco, mas o usuário foi criado no Auth, deleta ele para não "sujar"
      if (_supabase.auth.currentUser != null) {
        // Nota: Delete via Admin API não é permitido direto pelo cliente por segurança,
        // mas podemos deslogar.
        await logout();
      }
      rethrow;
    }
  }
}