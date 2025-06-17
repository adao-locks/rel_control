import 'package:flutter/material.dart';

class UpperCaseTextField extends StatefulWidget {
  const UpperCaseTextField({super.key});

  @override
  State<UpperCaseTextField> createState() => _UpperCaseTextFieldState();
}

class _UpperCaseTextFieldState extends State<UpperCaseTextField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}