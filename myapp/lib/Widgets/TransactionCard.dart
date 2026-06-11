import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Models/TransactionModel.dart';
import 'package:myapp/Widgets/HoverTapScale.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final int index;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', "id_ID");
    final color = _getColor();
    final isTransfer = transaction.type == "transfer";
    final amountPrefix = transaction.isExpense ? "-Rp. " : "+Rp. ";

    return HoverTapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      hoverScale: 1.018,
      pressScale: 0.975,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.18),
              spreadRadius: 0.2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.18),
              ),
              child: Icon(_getIcon(), color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title.isEmpty ? "Untitled" : transaction.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _subtitle(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (!isTransfer) ...[
              const SizedBox(width: 8),
              Text(
                "$amountPrefix${formatter.format(transaction.amount)}",
                style: TextStyle(
                  color: transaction.isExpense
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ] else
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    if (transaction.type == "transfer") {
      final from = transaction.fromWalletName.isEmpty
          ? "Wallet"
          : transaction.fromWalletName;
      final to = transaction.toWalletName.isEmpty
          ? "Wallet"
          : transaction.toWalletName;
      return "$from to $to - ${_formatDate()}";
    }

    return "${transaction.category} - ${_formatDate()}";
  }

  Color _getColor() {
    if (transaction.type == "transfer") {
      final hex = transaction.toWalletColorHex.replaceFirst("#", "");
      final parsed = int.tryParse(hex.length == 6 ? "FF$hex" : hex, radix: 16);
      return parsed == null ? Colors.blueGrey.shade700 : Color(parsed);
    }

    final hex = transaction.colorHex.replaceFirst("#", "");
    final parsed = int.tryParse(hex.length == 6 ? "FF$hex" : hex, radix: 16);
    if (parsed != null) return Color(parsed);

    if (index == 0) return Colors.red.shade700;
    if (index == 1) return Colors.blue.shade700;
    if (index == 2) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  IconData _getIcon() {
    if (transaction.type == "transfer") return Icons.swap_horiz;

    switch (transaction.iconName) {
      case "ic_swap_horiz":
        return Icons.swap_horiz;
      case "ic_restaurant":
      case "restaurant":
        return Icons.restaurant;
      case "ic_shopping_cart":
      case "shopping_cart":
        return Icons.shopping_cart;
      case "ic_work":
      case "work":
        return Icons.work;
      case "ic_movie":
      case "movie":
        return Icons.movie;
      case "ic_directions_car":
      case "transport":
        return Icons.directions_car;
      case "ic_home":
        return Icons.home;
      case "ic_payments":
      case "income":
        return Icons.payments;
      default:
        return _fallbackIcon();
    }
  }

  IconData _fallbackIcon() {
    switch (transaction.category) {
      case "Shopping":
        return Icons.shopping_cart;
      case "Food":
        return Icons.restaurant;
      case "Entertainment":
        return Icons.movie;
      case "Salary":
        return Icons.work;
      case "Transfer":
        return Icons.swap_horiz;
      default:
        return Icons.payments;
    }
  }

  String _formatDate() {
    return DateFormat.yMMMd().format(transaction.date);
  }
}
