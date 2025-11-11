import 'package:clicare/screens/register_choice_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para capturar o texto dos campos
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variáveis para controlar o estado da UI
  bool _isLoading = false;
  String _errorMessage = '';

  // Função para lidar com a submissão do formulário
  Future<void> _submitLogin() async {
    // Validação básica no lado do cliente
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, preencha todos os campos.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Limpa erros antigos
    });

    try {
      // Chama o método de login do nosso AuthProvider
      await Provider.of<AuthProvider>(context, listen: false).login(
        _emailController.text,
        _passwordController.text,
      );
      // Se o login for bem-sucedido, o Consumer no main.dart cuidará da navegação
    } catch (error) {
      // Se o login falhar, o AuthProvider lançará um erro
      setState(() {
        _errorMessage = 'Credenciais inválidas. Verifique seu e-mail e senha.';
      });
    } finally {
      // Garante que o indicador de loading pare, mesmo se houver erro
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cor primária da sua marca
    const primaryColor = Color(0xFF319F86);

    return Scaffold(
      // Equivalente ao seu 'background: linear-gradient(...)'
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // Centraliza o card de login
        child: Center(
          // Garante que o conteúdo role se a tela for pequena (ex: com teclado aberto)
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            // Equivalente à sua div.wrap > div.card
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.18),
                    blurRadius: 24,
                    offset: Offset(0, 6),
                  )
                ],
              ),
              // Equivalente ao aside.panel
              child: Column(
                mainAxisSize: MainAxisSize.min, // Ocupa o mínimo de espaço vertical
                children: [
                  // --- Cabeçalho do formulário ---
                  const Text(
                    'Entrar no Portal',
                    style: TextStyle(
                      fontSize: 26, // 1.6em
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Insira suas credenciais para acessar o sistema.',
                    style: TextStyle(color: Color(0xFF666), fontSize: 15), // 0.95em
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),

                  // --- Formulário ---
                  // Campo de E-mail
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Campo de Senha
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Mensagem de Erro ---
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // --- Ações (Botões) ---
                  // Botão Entrar
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                    width: double.infinity, // Ocupa toda a largura
                    child: ElevatedButton(
                      onPressed: _submitLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Botão Criar Conta
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Ação de navegação: Abre a tela de escolha de cadastro
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const RegisterChoiceScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryColor, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Criar conta',
                        style: TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // --- Rodapé do painel ---
                  const Text(
                    'Precisa de ajuda? Contato',
                    style: TextStyle(fontSize: 13, color: Color(0xFF888)),
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