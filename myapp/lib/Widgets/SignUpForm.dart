import 'package:flutter/material.dart';
import 'package:myapp/Screens/HomeScreen.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  bool isHidden = true;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Username"),
          const SizedBox(height: 6),
          TextFormField(
            decoration: InputDecoration(
              hintText: "Username",
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Username is required";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          const Text("Email Address"),
          const SizedBox(height: 6),
          TextFormField(
            decoration: InputDecoration(
              hintText: "yourname@example.com",
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Email is required";
              }
              if (!value.contains("@") || !value.contains(".com")) {
                return "Invalid Email";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          const Text("Password"),
          const SizedBox(height: 6),
          TextFormField(
            obscureText: isHidden,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock),
              hintText: "Enter your password",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    isHidden = !isHidden;
                  });
                },
                icon: Icon(isHidden ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Password is required";
              }
              if (!RegExp(r'[0-9]').hasMatch(value)) {
                return "Password must contain a number";
              }
              if (value.length < 8) {
                return "Password must be 8 characters or longer";
              }
              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                return "Password must contain an uppercase letter";
              }
              if (!RegExp(r'[a-z]').hasMatch(value)) {
                return "Password must contain a lowercase letter";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  print("valid");
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen()),
                  );
                }
              },
              child: const Text("Sign Up"),
            ),
          ),
        ],
      ),
    );
  }
}
