import 'package:flutter/material.dart';
import 'package:myapp/Models/TransactionModel.dart';
import 'package:myapp/Screens/TransactionDetailScreen.dart';
import 'package:myapp/Widgets/TransactionCard.dart';

class TransactionSection extends StatelessWidget {
  final List<TransactionModel> transactions;
  final VoidCallback? onTransactionChanged;

  const TransactionSection({
    super.key,
    required this.transactions,
    this.onTransactionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Transactions",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          const Center(child: Text("There are no transactions"))
        else
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return TransactionCard(
                transaction: tx,
                index: index,
                onTap: () => _openDetail(context, tx.id),
              );
            },
          ),
      ],
    );
  }

  Future<void> _openDetail(BuildContext context, String id) async {
    if (id.isEmpty) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transactionId: id),
      ),
    );
    if (changed == true) onTransactionChanged?.call();
  }
}
