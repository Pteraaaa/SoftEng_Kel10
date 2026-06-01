import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:myapp/Services/GoogleAuthService.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  bool isHidden = true;
  bool isSendingOtp = false;
  bool isRegistering = false;
  int otpCountdown = 0;
  String? selectedGender;
  DateTime? selectedDate;
  XFile? selectedImage;
  String? challengeToken;
  String? emailError;
  String? otpError;
  String? registerMessage;
  bool registerSuccess = false;
  Timer? otpTimer;

  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    otpTimer?.cancel();
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    otpController.dispose();
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
              controller: userNameController,
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

            const Text("Gender"),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: "Gender",
                prefixIcon: Icon(getGenderIcon()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              value: selectedGender,
              items: ["Male", "Female", "Others"]
                  .map(
                    (gender) =>
                        DropdownMenuItem(value: gender, child: Text(gender)),
                  )
                  .toList(),

              onChanged: (value) {
                setState(() {
                  selectedGender = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return "Gender is required";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            Text("Date of Birth"),
            const SizedBox(height: 6),
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: selectedDate == null
                    ? "Select your birth date"
                    : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1940),
                  lastDate: DateTime.now(),
                );

                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              validator: (_) {
                if (selectedDate == null) {
                  return "Date of Birth is required";
                }
                return null;
              },
            ),

            const SizedBox(height: 20),
            const Text("Email Address"),
            const SizedBox(height: 6),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: "yourname@example.com",
                prefixIcon: Icon(Icons.email),
                errorText: emailError,
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: otpCountdown > 0 || isSendingOtp
                        ? null
                        : sendOtp,
                    child: Text(
                      otpCountdown > 0 ? "${otpCountdown}s" : "Send OTP",
                    ),
                  ),
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 112),
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
              onChanged: (_) {
                setState(() {
                  challengeToken = null;
                  emailError = null;
                });
              },
            ),
            const SizedBox(height: 20),

            const Text("OTP"),
            const SizedBox(height: 6),
            TextFormField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Input OTP code",
                prefixIcon: const Icon(Icons.pin),
                errorText: otpError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "OTP is required";
                }
                return null;
              },
              onChanged: (_) {
                if (otpError != null) {
                  setState(() {
                    otpError = null;
                  });
                }
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

            const Text("Avatar"),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: pickAvatar,
              icon: const Icon(Icons.image),
              label: Text(
                selectedImage == null ? "Choose Avatar" : selectedImage!.name,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: isRegistering
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          await register();
                        }
                      },
                child: Text(isRegistering ? "Signing Up..." : "Sign Up"),
              ),
            ),
            if (registerMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                registerMessage!,
                style: TextStyle(
                  color: registerSuccess ? Colors.green : Colors.red,
                ),
              ),
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
                      registerSuccess = false;
                      registerMessage = error.toString();
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

  Future<void> sendOtp() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !email.contains("@") || !email.contains(".")) {
      setState(() {
        emailError = "Invalid Email";
      });
      return;
    }

    setState(() {
      isSendingOtp = true;
      emailError = null;
      registerMessage = null;
    });

    try {
      final result = await AuthService.verifyEmail(email);
      if (!mounted) return;
      setState(() {
        challengeToken = result.challengeToken;
      });
      startOtpCountdown();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        emailError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isSendingOtp = false;
        });
      }
    }
  }

  void startOtpCountdown() {
    otpTimer?.cancel();
    setState(() {
      otpCountdown = 60;
    });

    otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (otpCountdown <= 1) {
        timer.cancel();
        setState(() {
          otpCountdown = 0;
        });
        return;
      }

      setState(() {
        otpCountdown -= 1;
      });
    });
  }

  Future<void> register() async {
    if (challengeToken == null || challengeToken!.isEmpty) {
      setState(() {
        emailError = "Please send OTP first";
      });
      return;
    }

    setState(() {
      isRegistering = true;
      registerMessage = null;
      emailError = null;
      otpError = null;
    });

    try {
      await AuthService.registerLocal(
        name: userNameController.text.trim(),
        email: emailController.text.trim(),
        gender: selectedGender!,
        dob: selectedDate!.toIso8601String().split("T").first,
        password: passwordController.text,
        challengeToken: challengeToken!,
        otpCode: otpController.text.trim(),
        avatar: selectedImage,
      );

      if (!mounted) return;
      setState(() {
        registerSuccess = true;
        registerMessage = "Success Register";
      });
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      setState(() {
        registerSuccess = false;

        if (message == "Kode OTP tidak valid atau kadaluarsa.") {
          otpError = "OTP code not valid or already expired";
        } else if (message == "Email Sudah Terdaftar") {
          emailError = "Email already registered";
        } else {
          registerMessage = "Failed Register : $message";
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          isRegistering = false;
        });
      }
    }
  }

  Future<void> pickAvatar() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (!mounted) return;

    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  IconData getGenderIcon() {
    switch (selectedGender) {
      case "Male":
        return Icons.male;
      case "Female":
        return Icons.female;
      default:
        return Icons.person_2;
    }
  }
}
