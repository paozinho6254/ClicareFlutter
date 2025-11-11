import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ClinicRegisterScreen extends StatefulWidget {
  const ClinicRegisterScreen({super.key});

  @override
  _ClinicRegisterScreenState createState() => _ClinicRegisterScreenState();
}

class _ClinicRegisterScreenState extends State<ClinicRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Controladores para os campos da clínica
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _senhaConfirmController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _submitRegister() async {
    // 1. Valida os campos do formulário. Se inválido, não continua.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Inicia o estado de "carregando" na UI.
    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Limpa qualquer mensagem de erro anterior.
    });

    try {
      // 3. Monta o objeto de dados a ser enviado.
      final Map<String, dynamic> dadosCadastro = {
        "nome": _nomeController.text,
        "email": _emailController.text,
        "senha": _senhaController.text,
        "cnpj": _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        "_telefoneController": _telefoneController.text,
      };

      // 4. Tenta executar a operação de rede.
      await _apiService.registerPatient(dadosCadastro);

      // --- CAMINHO FELIZ (SUCESSO) ---
      if (mounted) {
        // Mostra uma mensagem de sucesso.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paciente cadastrado com sucesso! Redirecionando...'),
            backgroundColor: Colors.green,
          ),
        );

        // Aguarda um segundo e redireciona para a tela de login.
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      }

    } catch (error) {
      // 'error' contém a exceção lançada pelo ApiService.
      if (mounted) {
        setState(() {
          // 6. Atualiza a UI para mostrar a mensagem de erro para o usuário.
          // O replaceFirst remove o "Exception: " do início da mensagem para ficar mais limpo.
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
        });
      }

    } finally {
      // --- EXECUTA SEMPRE ---
      // 7. Garante que o indicador de carregamento seja desativado,
      //    permitindo que o usuário tente novamente.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF319F86);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Clínica'),
        backgroundColor: primaryColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cadastrar Clínica',
                    style: TextStyle(
                      fontSize: 26,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Clínica',
                    ),
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail de Contato',
                    ),
                    validator: (v) => v!.isEmpty || !v.contains('@')
                        ? 'E-mail inválido'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _cnpjController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CNPJ (apenas números)',
                    ),
                    validator: (v) =>
                        v!.length != 14 ? 'CNPJ deve ter 14 dígitos' : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _senhaController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    validator: (v) =>
                        v!.length < 6 ? 'A senha é muito curta' : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _senhaConfirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Senha',
                    ),
                    validator: (v) => v! != _senhaController.text
                        ? 'As senhas não coincidem'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Cadastrar',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
