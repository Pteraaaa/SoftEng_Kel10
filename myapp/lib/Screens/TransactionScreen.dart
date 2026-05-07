import 'package:flutter/material.dart';
import 'package:myapp/Models/TransactionModel.dart';
import 'package:myapp/Widgets/TransactionCard.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

enum FilterType { all, income, expense, transfer }

class _TransactionScreenState extends State<TransactionScreen> {
  FilterType selectedFilter = FilterType.all;

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

    final filtered = _getFiltered(transactions);

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
              _buildFilter("All", FilterType.all),
              _buildFilter("Income", FilterType.income),
              _buildFilter("Expense", FilterType.expense),
              _buildFilter("Transfer", FilterType.transfer),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children: [
                _sectionTitle("TODAY"),
                ...filtered
                    .where((t) => _isToday(t.date))
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (entry) => TransactionCard(
                        transaction: entry.value,
                        index: entry.key,
                      ),
                    ),

                _sectionTitle("YESTERDAY"),
                ...filtered
                    .where((t) => _isYesterday(t.date))
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (entry) => TransactionCard(
                        transaction: entry.value,
                        index: entry.key,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
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

  Widget _buildFilter(String text, FilterType type) {
    final isActive = selectedFilter == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.amber : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<TransactionModel> _getFiltered(List<TransactionModel> transaction) {
    switch (selectedFilter) {
      case FilterType.income:
        return transaction.where((t) => !t.isExpense).toList();
      case FilterType.expense:
        return transaction.where((t) => t.isExpense).toList();
      default:
        return transaction;
    }
  }
}
