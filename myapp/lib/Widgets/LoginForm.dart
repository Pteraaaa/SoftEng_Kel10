import 'package:flutter/material.dart';
import 'package:myapp/Screens/TemplateScreen.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:myapp/Services/GoogleAuthService.dart';
import 'package:myapp/Services/TokenStorage.dart';

class LoginForm extends StatefulWidget {
  final String? initialError;

  const LoginForm({super.key, this.initialError});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool isHidden = true;
  bool isLoading = false;
  String? loginError;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    loginError = widget.initialError;
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Username"),
            const SizedBox(height: 6),
            TextFormField(
              controller: usernameController,
              decoration: InputDecoration(
                hintText: "Input your username",
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

            const Text("Password"),
            const SizedBox(height: 6),
            TextFormField(
              controller: passwordController,
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
                  icon: Icon(
                    isHidden ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            isLoading = true;
                            loginError = null;
                          });

                          try {
                            final authResult = await AuthService.loginLocal(
                              username: usernameController.text,
                              password: passwordController.text,
                            );

                            await TokenStorage.saveTokens(
                              accessToken: authResult.accessToken,
                              refreshToken: authResult.refreshToken,
                            );

                            final user = await AuthService.getMeWithRefresh();

                            if (!context.mounted) return;

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TemplateScreen(user: user),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            if (error is TokenExpiredException) {
                              await showSessionExpiredDialog(context);
                              await TokenStorage.clear();
                              return;
                            }

                            setState(() {
                              loginError = error.toString();
                            });
                          } finally {
                            if (mounted) {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        }
                      },
                child: Text(isLoading ? "Logging in..." : "Login"),
              ),
            ),
            if (loginError != null) ...[
              const SizedBox(height: 8),
              Text(loginError!, style: const TextStyle(color: Colors.red)),
            ],
            SizedBox(height: 15),

            Row(
              children: [
                const Expanded(child: Divider(thickness: 1)),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("OR"),
                ),

                const Expanded(child: Divider(thickness: 1)),
              ],
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Image.asset("assets/images/Google.png", height: 24),
                label: const Text("Login with Google"),
                onPressed: () async {
                  try {
                    await GoogleAuthService.redirectToBackend();
                  } catch (error) {
                    setState(() {
                      loginError = error.toString();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showSessionExpiredDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Session Expired"),
          content: const Text("Session Expired please login again"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
