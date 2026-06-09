import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Models/TransactionModel.dart';
import 'package:myapp/Services/AuthService.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? transaction;
  bool isLoading = true;
  String? errorMessage;

  final currency = NumberFormat.currency(
    locale: "id_ID",
    symbol: "Rp. ",
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        title: const Text("Transaction Detail"),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? _ErrorState(message: errorMessage!, onRetry: _loadDetail)
            : _buildDetail(transaction!),
      ),
    );
  }

  Widget _buildDetail(TransactionModel item) {
    final color = item.type == "transfer"
        ? _parseColor(item.toWalletColorHex, fallback: Colors.blueGrey)
        : _parseColor(item.colorHex, fallback: Colors.amber);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconFor(item), color: color, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  item.title.isEmpty ? "Untitled" : item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (item.type == "transfer")
                  Text(
                    "Wallet Transfer",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    "${item.type.toUpperCase()} - ${item.category}",
                    style: TextStyle(
                      color: item.isExpense
                          ? Colors.red.shade600
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (item.type != "transfer") ...[
                  const SizedBox(height: 12),
                  Text(
                    "${item.isExpense ? '-' : '+'}${currency.format(item.amount)}",
                    style: TextStyle(
                      color: item.isExpense
                          ? Colors.red.shade600
                          : Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (item.type == "transfer") _TransferPanel(item: item),
          if (item.type != "transfer")
            _DetailPanel(
              rows: [
                _DetailRow("Category", item.category),
                _DetailRow(
                  item.isExpense ? "From Wallet" : "To Wallet",
                  item.isExpense ? item.fromWalletName : item.toWalletName,
                ),
                _DetailRow("Amount", currency.format(item.amount)),
              ],
            ),
          const SizedBox(height: 14),
          _DetailPanel(
            rows: [
              _DetailRow("Date", DateFormat.yMMMMd().format(item.date)),
              _DetailRow("Time", DateFormat.Hm().format(item.date)),
              _DetailRow("Day", item.day.isEmpty ? "-" : item.day),
              _DetailRow("Note", item.note.isEmpty ? "-" : item.note),
              _DetailRow("Transaction ID", item.id),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final detail = await AuthService.getTransactionDetail(
        widget.transactionId,
      );

      if (!mounted) return;
      setState(() {
        transaction = detail;
      });
    } on ApiException catch (err) {
      if (!mounted) return;
      setState(() => errorMessage = err.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = "Failed to load transaction detail");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  IconData _iconFor(TransactionModel item) {
    if (item.type == "transfer") return Icons.swap_horiz;
    if (item.iconName == "ic_restaurant") return Icons.restaurant;
    if (item.iconName == "ic_shopping_cart") return Icons.shopping_cart;
    if (item.iconName == "ic_directions_car") return Icons.directions_car;
    if (item.iconName == "ic_work") return Icons.work;
    return Icons.payments;
  }

  Color _parseColor(String value, {required Color fallback}) {
    final hex = value.replaceFirst("#", "");
    final parsed = int.tryParse(hex.length == 6 ? "FF$hex" : hex, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}

class _TransferPanel extends StatelessWidget {
  final TransactionModel item;

  const _TransferPanel({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: _WalletNode(label: "From", name: item.fromWalletName)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward, color: Colors.grey.shade500),
          ),
          Expanded(child: _WalletNode(label: "To", name: item.toWalletName)),
        ],
      ),
    );
  }
}

class _WalletNode extends StatelessWidget {
  final String label;
  final String name;

  const _WalletNode({required this.label, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_wallet_outlined),
        ),
        const SizedBox(height: 8),
        Text(
          name.isEmpty ? "Wallet" : name,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final List<_DetailRow> rows;

  const _DetailPanel({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 112,
                      child: Text(
                        row.label,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value.isEmpty ? "-" : row.value,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade500, size: 36),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text("Try Again")),
          ],
        ),
      ),
    );
  }
}
