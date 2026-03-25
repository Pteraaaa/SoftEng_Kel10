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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bank Name"),
            const SizedBox(height: 6),

            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: "ABC Bank",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 6),

            const Text("Account Number"),
            const SizedBox(height: 6),

            TextFormField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: "Ex: 1234 1234 1234",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 6),

            const Text("Account Balance"),
            const SizedBox(height: 6),

            TextFormField(
              controller: balanceController,
              decoration: InputDecoration(
                hintText: "10000",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
