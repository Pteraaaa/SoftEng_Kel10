import 'package:flutter/material.dart';
import '../Widgets/LoginForm.dart';
import '../Widgets/SignUpForm.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 60),

            const Text(
              "Welcome Back",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isLogin = true;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLogin ? Colors.white : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isLogin ? Colors.amber : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isLogin = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: !isLogin ? Colors.white : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "Sign-Up",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !isLogin ? Colors.amber : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            isLogin ? const LoginForm() : const SignUpForm(),
          ],
        ),
      ),
    );
  }
}
