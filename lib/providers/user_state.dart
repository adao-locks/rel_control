import 'package:flutter/material.dart';

class UserState with ChangeNotifier {
  String tipoUsuario = '';
  String username = '';

  void setUser(String tipo, String nome) {
    tipoUsuario = tipo;
    username = nome;
    notifyListeners();
  }

  void clearUser() {
    tipoUsuario = '';
    username = '';
    notifyListeners();
  }
}
