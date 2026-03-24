import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WalletCard extends StatefulWidget {
  final String title;
  final String code;
  final int balance;

  const WalletCard({
    super.key,
    required this.title,
    required this.code,
    required this.balance,
  });

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  bool hideCard = true;
  bool hideBalance = true;

  final formatter = NumberFormat.currency(
    locale: "id_ID",
    symbol: "Rp. ",
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 2, 56, 101),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.credit_card, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 5),
          Text(
            widget.title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 10,
            ),
          ),
          Row(
            children: [
              Text(
                hideCard
                    ? "**** ${widget.code.substring(widget.code.length - 4)}"
                    : widget.code,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 15),

              IconButton(
                onPressed: () {
                  setState(() {
                    hideCard = !hideCard;
                  });
                },
                icon: hideCard
                    ? Icon(Icons.visibility)
                    : Icon(Icons.visibility_off),
                color: Colors.white,
                iconSize: 20,
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                hideBalance ? "Rp. ••••••" : formatter.format(widget.balance),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 15),

              IconButton(
                onPressed: () {
                  setState(() {
                    hideBalance = !hideBalance;
                  });
                },
                icon: hideBalance
                    ? Icon(Icons.visibility)
                    : Icon(Icons.visibility_off),
                color: Colors.white,
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
