import 'package:flutter/material.dart';
import 'package:myapp/Widgets/WalletCard.dart';

class WalletSection extends StatelessWidget {
  const WalletSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "My Wallet",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            IconButton(onPressed: () {}, icon: Icon(Icons.add)),
          ],
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            children: [
              WalletCard(
                title: "BCA Account",
                code: "1011 1012 1000",
                balance: 20000000,
              ),
              WalletCard(
                title: "BCA Account",
                code: "1011 1012 1000",
                balance: 20000000,
              ),
              WalletCard(
                title: "BCA Account",
                code: "1011 1012 1000",
                balance: 20000000,
              ),
              WalletCard(
                title: "BCA Account",
                code: "1011 1012 1000",
                balance: 20000000,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
