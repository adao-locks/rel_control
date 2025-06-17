import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  void login({required bool checkUser}) {
    String user = usernameController.text.trim();

    if (checkUser && user.isEmpty) {
    if (checkUser && user.isEmpty) {
      setState(() {
        errorMessage = 'Informe o nome de usuário';
      });
      return;
    }

    String tipo;
    if (checkUser && user.toLowerCase() == 'admin') {
      tipo = 'admin';
    } else if (checkUser && user.toLowerCase() == 'supervisor') {
      tipo = 'supervisor';
    } else {
      tipo = 'user';
    }

    // 🔥 Salvar no Provider
    final userState = Provider.of<UserState>(context, listen: false);
    userState.setUser(tipo, user);

    setState(() {
      errorMessage = '';
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ClientPage(),
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
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => login(checkUser: true),
                  child: const Text('Entrar'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => login(checkUser: false),
                  child: const Text('Entrar como Visitante'),
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
