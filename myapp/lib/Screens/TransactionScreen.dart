import 'package:flutter/material.dart';
import 'package:myapp/Models/TransactionModel.dart';
import 'package:myapp/Widgets/TransactionCard.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  @override
  Widget build(BuildContext context) {
    final transactions = [
      TransactionModel(
        title: "Whole Foods Market",
        category: "Shopping",
        amount: 150000,
        date: DateTime.now(),
        isExpense: true,
      ),
      TransactionModel(
        title: "Freelance Project",
        category: "Salary",
        amount: 2500000,
        date: DateTime.now(),
        isExpense: false,
      ),
      TransactionModel(
        title: "Uber Ride",
        category: "Transport",
        amount: 50000,
        date: DateTime.now(),
        isExpense: true,
      ),
      TransactionModel(
        title: "Netflix Subscription",
        category: "Entertainment",
        amount: 120000,
        date: DateTime.now().subtract(const Duration(days: 1)),
        isExpense: true,
      ),
      TransactionModel(
        title: "Dinner at Mario's",
        category: "Food",
        amount: 200000,
        date: DateTime.now().subtract(const Duration(days: 1)),
        isExpense: true,
      ),
    ];

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Transaction",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              IconButton(onPressed: () {}, icon: Icon(Icons.calendar_today)),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(onPressed: () {}, child: Text("All")),
              ElevatedButton(onPressed: () {}, child: Text("Income")),
              ElevatedButton(onPressed: () {}, child: Text("Expense")),
              ElevatedButton(onPressed: () {}, child: Text("Transfer")),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children: [
                _sectionTitle("TODAY"),
                ...List.generate(
                  3,
                  (index) => TransactionCard(
                    transaction: transactions[index],
                    index: index,
                  ),
                ),

                _sectionTitle("YESTERDAY"),
                ...List.generate(
                  2,
                  (index) => TransactionCard(
                    transaction: transactions[index + 3],
                    index: index,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _FilterButton(String title) {
    return SizedBox(
      child: ElevatedButton(onPressed: () {}, child: Text(title)),
    );
  }

  static Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
