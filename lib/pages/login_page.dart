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
      AlertDialog(
        title: const Text('Atenção'),
        content: const Text(
          'Você está logando como administrador. '
          'Tenha cuidado ao realizar alterações no sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    } else {
      tipo = 'user';
      AlertDialog(
        title: const Text('Atenção'),
        content: const Text(
          'Você está logando como usuário. '
          'Algumas funcionalidades podem ser limitadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
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
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(125, 192, 21, 21),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'RelControl',
                applicationVersion: '1.3.48',
                applicationIcon: const Icon(Icons.computer),
                children: [
                  const Text(
                    'Aplicativo de controle de relatório para supervisão e automação.',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Desenvolvido por Eduardo Adão Locks e Vinicius Brehmer',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 400, right: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Usuário',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                final upperValue = value.toUpperCase();
                if (value != upperValue) {
                  usernameController.value = usernameController.value.copyWith(
                    text: upperValue,
                    selection: TextSelection.collapsed(
                      offset: upperValue.length,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => login(checkUser: true),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(
                      color: Color.fromARGB(125, 192, 21, 21),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () => login(checkUser: false),
                  child: const Text(
                    'Entrar como Visitante',
                    style: TextStyle(
                      color: Color.fromARGB(125, 192, 21, 21),
                      fontWeight: FontWeight.bold,
                    ),),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
    );
  }
}
