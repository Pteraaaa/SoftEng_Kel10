import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TotalBalance extends StatelessWidget {
  final int balance;

  const TotalBalance({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp. ",
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFFE082)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            "Total Balance",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),

          const SizedBox(height: 8),

          Text(
            formatter.format(balance),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
