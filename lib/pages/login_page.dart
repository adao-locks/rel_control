import 'package:flutter/material.dart';
import 'package:rel_control/pages/client_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String tipoUsuario = '';
  String errorMessage = '';

  void login() {
    String username = usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        errorMessage = 'Informe o nome de usuário';
      });
      return;
    }

    if (username.toLowerCase() == 'admin') {
      tipoUsuario = 'admin';
    } else {
      tipoUsuario = 'user';
    }

    setState(() {
      errorMessage = '';
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ClientPage(tipoUsuario: tipoUsuario, username: username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Usuário',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                final upperValue = value.toUpperCase();
                if (value != upperValue) {
                  usernameController.value = usernameController.value.copyWith(
                    text: upperValue,
                    selection: TextSelection.collapsed(offset: upperValue.length),
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
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: login,
              child: const Text('Entrar'),
            ),
            const SizedBox(height: 8),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}