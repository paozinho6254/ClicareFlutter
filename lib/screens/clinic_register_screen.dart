import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class ClinicRegisterScreen extends StatefulWidget {
  const ClinicRegisterScreen({super.key});

  @override
  _ClinicRegisterScreenState createState() => _ClinicRegisterScreenState();
}

class _ClinicRegisterScreenState extends State<ClinicRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de Texto
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _senhaConfirmController = TextEditingController();

  final cnpjFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _submitRegister() async {
    // 1. Validação do Formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 2. Chamada ao AuthProvider (Supabase)
      await Provider.of<AuthProvider>(context, listen: false).registerClinic(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        password: _senhaController.text,
        // Remove pontuação básica do CNPJ se o usuário digitar
        cnpj: _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        telefone: _telefoneController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clínica cadastrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // O AuthProvider já loga o usuário automaticamente.
        // Podemos limpar a pilha e deixar o main.dart redirecionar,
        // ou forçar a ida para a Home.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          // Tratamento simples de erro
          if (error.toString().contains('User already registered')) {
            _errorMessage = 'Este e-mail já está em uso.';
          } else {
            _errorMessage = 'Erro no cadastro: ${error.toString()}';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Boas Práticas: Limpar controladores ao sair da tela
    _nomeController.dispose();
    _emailController.dispose();
    _cnpjController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _senhaConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF319F86);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [primaryColor, primaryColor]),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_hospital,
                      size: 50,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Cadastrar Clínica',
                      style: TextStyle(
                        fontSize: 24,
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Nome Fantasia
                    TextFormField(
                      controller: _nomeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Clínica / Fantasia',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),

                    // CNPJ
                    TextFormField(
                      controller: _cnpjController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [cnpjFormatter],
                      // <--- Adicione isto
                      decoration: const InputDecoration(
                        labelText: 'CNPJ',
                        hintText: '00.000.000/0000-00',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Campo obrigatório';
                        if (v.length < 18)
                          return 'CNPJ incompleto'; // 18 é o tamanho com pontos e traços
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Telefone
                    TextFormField(
                      controller: _telefoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [telefoneFormatter],
                      // <--- Adicione isto
                      decoration: const InputDecoration(
                        labelText: 'Telefone Comercial',
                        hintText: '(99) 99999-9999',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.length < 14 ? 'Telefone incompleto' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail de Acesso',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty || !v.contains('@')
                          ? 'E-mail inválido'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Senha
                    TextFormField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 16),

                    // Confirmar Senha
                    TextFormField(
                      controller: _senhaConfirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar Senha',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v! != _senhaController.text
                          ? 'As senhas não coincidem'
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // Exibição de Erro
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

                    // Botão de Cadastro
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Finalizar Cadastro',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 10),

                    // --- BOTÃO JÁ TENHO CONTA ---
                    TextButton(
                      onPressed: () {
                        // Remove todas as telas de cadastro da pilha e volta para a primeira (Login)
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: 'Já possui cadastro? ',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Fazer Login',
                              style: TextStyle(
                                color: Color(0xFF319F86), // primaryColor
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
