import 'package:flutter/material.dart';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final titleController = TextEditingController();
  final codeController = TextEditingController();
  final balanceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Wallet")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Bank Name"),
            ),
            TextField(
              controller: codeController,
              decoration: InputDecoration(labelText: "Bank Number"),
            ),
            TextField(
              controller: balanceController,
              decoration: InputDecoration(labelText: "Account Balance"),
            ),

            SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                final title = titleController.text;
                final code = codeController.text;
                final balance = int.tryParse(balanceController.text) ?? 0;

                Navigator.pop(context, {
                  "title": title,
                  "code": code,
                  "balance": balance,
                });
              },

              child: const Text("Add Wallet"),
            ),
          ],
        ),
      ),
    );
  }
}
