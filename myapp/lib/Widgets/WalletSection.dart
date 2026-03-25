import 'package:flutter/material.dart';
import 'package:myapp/Models/WalletModel.dart';
import 'package:myapp/Widgets/WalletCard.dart';

class WalletSection extends StatelessWidget {
  final List<WalletModel> wallets;
  final VoidCallback onAddWallet;

  const WalletSection({
    super.key,
    required this.wallets,
    required this.onAddWallet,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "My Wallet",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),

              IconButton(onPressed: onAddWallet, icon: Icon(Icons.add)),
            ],
          ),

          const SizedBox(height: 8),

          if (wallets.isEmpty)
            GestureDetector(
              onTap: onAddWallet,
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Center(child: Text("+ Add Your First Wallet!")),
              ),
            )
          else
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: wallets.length + 1,
                itemBuilder: (context, index) {
                  if (index == wallets.length) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: AddWalletCard(onTap: onAddWallet),
                    );
                  }
                  final wallet = wallets[index];

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: WalletCard(
                      title: wallet.title,
                      code: wallet.code,
                      balance: wallet.balance,
                      index: index,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class AddWalletCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddWalletCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Icon(Icons.add, size: 40)),
      ),
    );
  }
}
