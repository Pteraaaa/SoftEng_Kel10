import 'package:flutter/material.dart';
import 'package:myapp/Services/AppCurrencyService.dart';
import 'package:myapp/Utils/MoneyFormatter.dart';
import 'package:myapp/Widgets/HoverTapScale.dart';

class WalletCard extends StatefulWidget {
  final String title;
  final String code;
  final num balance;
  final int index;
  final String colorHex;

  const WalletCard({
    super.key,
    required this.title,
    required this.code,
    required this.balance,
    required this.index,
    this.colorHex = "",
  });

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  final List<List<Color>> cardGradients = [
    [Color.fromARGB(255, 2, 56, 101), Color.fromARGB(255, 23, 83, 151)],
    [Colors.amber, Colors.yellow],
    [Colors.black, Colors.grey],
  ];

  bool hideCard = true;

  @override
  Widget build(BuildContext context) {
    final baseColor = _parseColor(widget.colorHex);
    final colors = widget.colorHex.isEmpty
        ? cardGradients[widget.index % cardGradients.length]
        : [baseColor, Color.lerp(baseColor, Colors.black, 0.28)!];

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white.withOpacity(0.82),
                  size: 18,
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.white, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.title.isEmpty ? "Wallet" : widget.title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  hideCard ? "**** ${_lastFourDigits()}" : widget.code,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              HoverTapScale(
                onTap: () {
                  setState(() {
                    hideCard = !hideCard;
                  });
                },
                borderRadius: BorderRadius.circular(999),
                child: Icon(
                  hideCard ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const Spacer(),
          ValueListenableBuilder<String>(
            valueListenable: AppCurrencyService.currency,
            builder: (context, currency, _) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  MoneyFormatter.format(widget.balance, currency: currency),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _lastFourDigits() {
    if (widget.code.length <= 4) return widget.code;
    return widget.code.substring(widget.code.length - 4);
  }

  Color _parseColor(String value) {
    final hex = value.replaceFirst("#", "");
    final parsed = int.tryParse(hex.length == 6 ? "FF$hex" : hex, radix: 16);
    return parsed == null ? const Color(0xFF1E3A5F) : Color(parsed);
  }
}
