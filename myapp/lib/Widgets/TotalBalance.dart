import 'package:flutter/material.dart';

class TotalBalance extends StatelessWidget {
  const TotalBalance({super.key});

  @override
  Widget build(BuildContext context) {
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

          Text("Rp. 24,054,000"),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
