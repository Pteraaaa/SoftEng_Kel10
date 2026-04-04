import 'package:flutter/material.dart';
import 'package:myapp/Models/UsersModel.dart';
import 'package:myapp/Screens/TemplateScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/Services/UserStore.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  bool isHidden = true;
  String? selectedGender;
  DateTime? selectedDate;
  XFile? selectedImage;

  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

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
                    UsersModel user = UsersModel(
                      username: userNameController.text,
                      gender: selectedGender!,
                      dob: selectedDate!,
                      email: emailController.text,
                      password: passwordController.text,
                      profileImage: "assests/images/default_profile.jpg",
                    );

                    UserStore.addUser(user);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TemplateScreen(user: user),
                      ),
                    );
                  }
                },
                child: const Text("Sign Up"),
              ),
            ),
          ],
        ),
      ),
    );
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
