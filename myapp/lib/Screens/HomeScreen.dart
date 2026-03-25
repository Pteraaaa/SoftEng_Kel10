import 'package:flutter/material.dart';
import 'package:myapp/Models/TransactionModel.dart';
import 'package:myapp/Models/WalletModel.dart';
import 'package:myapp/Screens/AddWalletScreen.dart';
import 'package:myapp/Widgets/InfoCard.dart';
import 'package:myapp/Widgets/WalletSection.dart';
import '../Widgets/TotalBalance.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<WalletModel> wallets = [];

  List<TransactionModel> transactions = [
    TransactionModel(
      title: "Amazon",
      category: "Shopping",
      date: DateTime.now(),
      amount: 54000,
      isExpense: true,
    ),
    TransactionModel(
      title: "Uber Eats",
      category: "Food",
      date: DateTime.now().subtract(const Duration(days: 1)),
      amount: 20000,
      isExpense: true,
    ),
    TransactionModel(
      title: "Upwork Inc.",
      category: "Salary",
      date: DateTime.now().subtract(const Duration(days: 3)),
      amount: 85000,
      isExpense: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Welcome Back",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "John Doe",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(onPressed: () {}, icon: Icon(Icons.notifications)),
                ],
              ),

              const SizedBox(height: 12),
              TotalBalance(balance: 24054000),

              const SizedBox(height: 12),
              Row(
                children: [
                  Infocard(
                    title: "Income",
                    amount: 420000,
                    icon: Icons.arrow_downward,
                    iconColor: Colors.green,
                    backgroundColor: Colors.green[100]!,
                  ),

                  const SizedBox(width: 10),

                  Infocard(
                    title: "Expenses",
                    amount: 420000,
                    icon: Icons.arrow_upward,
                    iconColor: Colors.red,
                    backgroundColor: Colors.red[100]!,
                  ),
                ],
              ),

              const SizedBox(height: 15),
              WalletSection(
                wallets: wallets,
                onAddWallet: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddWalletScreen()),
                  );

                  if (result != null) {
                    addWallet(
                      WalletModel(
                        title: result["title"],
                        code: result["code"],
                        balance: result["balance"],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addWallet(WalletModel wallet) {
    setState(() {
      wallets.add(wallet);
    });
  }
}
