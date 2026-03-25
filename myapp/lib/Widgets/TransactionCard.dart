import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Models/TransactionModel.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final int index;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.orange,
      Colors.green,
    ];

    final formatter = NumberFormat('#.###', "id_ID");

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 0.3,
            blurRadius: 2,
            offset: Offset(6, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getColor().withOpacity(0.3),
            ),
            child: Icon(_getIcon(), color: _getColor()),
          ),

          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2),
              Text(
                "${transaction.category} • ${_formatDate()}",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 5,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),
          Text(
            "${transaction.isExpense ? '-' : '+'}Rp. ${formatter.format(transaction.amount)}",
            style: TextStyle(
              color: transaction.isExpense
                  ? Colors.red.shade600
                  : Colors.green.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    if (index == 0) {
      return Colors.red.shade700;
    } else if (index == 1) {
      return Colors.blue.shade700;
    } else if (index == 2) {
      return Colors.orange.shade700;
    }
    return Colors.green.shade700;
  }

  IconData? _getIcon() {
    switch (transaction.category) {
      case "Shopping":
        return Icons.shopping_cart;
      case "Food":
        return Icons.restaurant;
      case "Entertainment":
        return Icons.movie;
      case "Salary":
        return Icons.work;
      default:
        return Icons.money;
    }
  }

  String _formatDate() {
    return DateFormat.yMMMd().format(transaction.date);
  }
}
