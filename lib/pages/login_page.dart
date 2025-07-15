import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rel_control/db.dart';
import 'package:rel_control/pages/client_page.dart';
import 'package:rel_control/providers/user_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = '';

  Future<void> login({required bool checkUser}) async {
    String userType = '';

    if (!checkUser) {
      usernameController.text = 'user';
      passwordController.text = '123';
      userType = 'user';
    }

    String user = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (user.isEmpty) {
      setState(() {
        errorMessage = 'Informe o nome de usuário';
      });
      return;
    }
    if (password.isEmpty) {
      setState(() {
        errorMessage = 'Informe a senha';
      });
      return;
    }

    final conn = await DB.connect();
    final result = await conn.mappedResultsQuery(
      'SELECT username, password, type FROM users WHERE username = @username',
      substitutionValues: {'username': user.toLowerCase()},
    );    
    if (result.isEmpty) {
      setState(() {
        errorMessage = 'Usuário não existe!';
      });
      return;
    }
    final row = result.first['users']!;
    final userName = row['username'] as String;
    final userPassword = row['password'] as String;
    userType = row['type'] as String;
    final checkUserResult = userType.toLowerCase();

    if (userName != user.toLowerCase()) {
      setState(() {
        errorMessage = 'Usuário não encontrado!';
      });
      return;
    }
    if (password != userPassword.toString()) {
      setState(() {
        errorMessage = 'Senha incorreta!';
      });
      return;
    }

    String tipo;
    if (checkUserResult.toString() == 'admin') {
      tipo = 'admin';
    } else {
      tipo = 'user';
    }

    final userState = Provider.of<UserState>(context, listen: false);
    userState.setUser(tipo, user);

    setState(() {
      errorMessage = '';
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ClientPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        backgroundColor: Color.fromARGB(125, 192, 21, 21),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Sobre',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'RelControl',
                applicationVersion: '1.3.47',
                applicationIcon: const Icon(Icons.computer),
                children: const [
                  Text(
                    'Aplicativo de controle de relatório para supervisão e automação.',
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Desenvolvido por Eduardo Adão Locks e Vinicius Brehmer',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Bem-vindo ao RelControl',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuário',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    final upper = value.toUpperCase();
                    if (value != upper) {
                      usernameController.value = usernameController.value.copyWith(
                        text: upper,
                        selection: TextSelection.collapsed(offset: upper.length),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        onPressed: () => login(checkUser: true),
                        label: const Text('Entrar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(125, 192, 21, 21),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => login(checkUser: false),
                  child: const Text(
                    'Entrar como visitante',
                    style: TextStyle(color: Color.fromARGB(125, 192, 21, 21),),
                  ),
                ),
                const SizedBox(height: 16),
                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}