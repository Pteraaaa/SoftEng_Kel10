import 'package:flutter/material.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Email Address"),
        TextField(
          decoration: InputDecoration(
            hintText: "yourname@example.com",
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        const Text("Password"),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock),
            hintText: "Enter your password",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () {}, child: const Text("Login")),
      ],
    );
  }
}
