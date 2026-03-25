import 'package:flutter/material.dart';
import 'package:myapp/Models/TransactionModel.dart';
import 'package:myapp/Widgets/TransactionCard.dart';

class TransactionSection extends StatelessWidget {
  final List<TransactionModel> transactions;

  const TransactionSection({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Transactions",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        if (transactions.isEmpty)
          const Center(child: Text("There are no transactions"))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              return TransactionCard(
                transaction: transactions[index],
                index: index,
              );
            },
          ),
      ],
    );
  }
}
