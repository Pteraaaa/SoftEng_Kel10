import 'package:flutter/material.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: "Input Email",
            hintText: "yourname@example.com",
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          obscureText: true,
          decoration: InputDecoration(labelText: "Password"),
        ),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () {}, child: const Text("Login")),
      ],
    );
  }
}
