import 'package:flutter/material.dart';

class TotalBalance extends StatelessWidget {
  const TotalBalance({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text("Total Balance"),

          const SizedBox(height: 8),

          Text("Rp. 24,054,000"),
        ],
      ),
    );
  }
}
