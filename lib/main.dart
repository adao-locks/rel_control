import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rel_control/pages/login_page.dart';
import 'package:rel_control/pages/client_page.dart';
import 'package:rel_control/providers/user_state.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await DB.connect();
  // runApp(const MyApp());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RelControl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/client': (context) => const ClientPage(),
      },
    );
  }
}
