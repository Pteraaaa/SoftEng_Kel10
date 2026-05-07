import 'package:flutter/material.dart';
import 'package:myapp/Screens/TemplateScreen.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

enum TransactionType { expense, income, transfer }

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  TransactionType selectedType = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                  const Text(
                    "Add Transaction",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text("Save")),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    buildTypeButton("Expense", TransactionType.expense),
                    buildTypeButton("Income", TransactionType.income),
                    buildTypeButton("Transfer", TransactionType.transfer),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text("Amount"),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTypeButton(String text, TransactionType type) {
    final isSelected = selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedType = type;
          });
        },

        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),

          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
