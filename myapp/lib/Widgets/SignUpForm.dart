import 'package:flutter/material.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Email Address"),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: "yourname@example.com",
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        const Text("Password"),
        const SizedBox(height: 6),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock),
            hintText: "Enter your password",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {},
            child: const Text("Sign Up"),
          ),
        ),
      ],
    );
  }
}
