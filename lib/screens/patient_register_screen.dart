import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PatientRegisterScreen extends StatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  _PatientRegisterScreenState createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para cada campo
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _senhaConfirmController = TextEditingController();

  final cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final dataFormatter = MaskTextInputFormatter(
    mask: '####-##-##',
    // Formato do banco (Ano-Mes-Dia) ou '##/##/####' se preferir visual BR
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _submitRegister() async {
    // 1. Valida o formulário. Se algum campo estiver inválido, a execução para aqui.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Ativa o indicador de carregamento e limpa erros antigos.
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 3. CHAMA O MÉTODO 'registerPatient' DO AUTHPROVIDER DIRETAMENTE
      //    Passando os valores dos controllers para os parâmetros nomeados.
      await Provider.of<AuthProvider>(context, listen: false).registerPatient(
        email: _emailController.text,
        password: _senhaController.text,
        nome: _nomeController.text,
        cpf: _cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        // Remove formatação do CPF
        dataNascimento: _dataNascimentoController.text,
        telefone: '',
      );

      // --- CAMINHO DE SUCESSO ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso! Faça o login.'),
            backgroundColor: Colors.green,
          ),
        );

        // Volta para a tela de login.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      // --- CAMINHO DE ERRO ---
      // Se o Supabase retornar um erro (ex: email já existe), ele será capturado aqui.
      if (mounted) {
        setState(() {
          // Exibe a mensagem de erro vinda do Supabase/AuthProvider.
          print('Usuário de paciente já existente!');
        });
      }
    } finally {
      // --- EXECUTA SEMPRE ---
      // Garante que o indicador de carregamento seja desativado.
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [primaryColor, primaryColor]),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              // decoração do container da tela
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                // mete sombrinha
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
                    const Icon(Icons.person, size: 50, color: primaryColor),
                    const SizedBox(height: 10),
                    const Text(
                      'Cadastrar Paciente',
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
                        labelText: 'Nome Completo',
                      ),
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (v) => v!.isEmpty || !v.contains('@')
                          ? 'E-mail inválido'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _cpfController,
                      keyboardType: TextInputType.number,
                      // AQUI ESTA A MÁGICA:
                      inputFormatters: [cpfFormatter],
                      decoration: const InputDecoration(
                        labelText: 'CPF',
                        hintText: '000.000.000-00',
                      ),
                      validator: (v) {
                        // Valida se está preenchido e se tem o tamanho completo da máscara
                        if (v == null || v.isEmpty || v.length < 14) {
                          return 'CPF incompleto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _dataNascimentoController,
                      decoration: const InputDecoration(
                        labelText: 'Data de Nascimento (AAAA-MM-DD)',
                      ),
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha (mínimo 6 caracteres)',
                      ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
                    const SizedBox(height: 12),
                    const SizedBox(height: 20),

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
