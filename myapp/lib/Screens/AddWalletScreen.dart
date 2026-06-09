import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Services/AuthService.dart';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final titleController = TextEditingController();
  final codeController = TextEditingController();
  final balanceController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isSubmitting = false;
  String? errorMessage;
  String selectedColorHex = "#1E3A5F";

  final colorOptions = const [
    "#1E3A5F",
    "#2563EB",
    "#7C3AED",
    "#047857",
    "#B45309",
    "#B91C1C",
  ];

  @override
  void dispose() {
    titleController.dispose();
    codeController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("Add Wallet"),
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WalletPreview(
                  title: titleController.text.trim(),
                  accountNumber: codeController.text.trim(),
                  balance: num.tryParse(balanceController.text.trim()) ?? 0,
                  colorHex: selectedColorHex,
                ),
                const SizedBox(height: 22),
                _FieldLabel(label: "Wallet Name"),
                const SizedBox(height: 8),
                _WalletTextField(
                  controller: titleController,
                  hintText: "Cash, BCA, Savings",
                  icon: Icons.account_balance_wallet_outlined,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if ((value ?? "").trim().isEmpty) {
                      return "Wallet name is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _FieldLabel(label: "Account Number"),
                const SizedBox(height: 8),
                _WalletTextField(
                  controller: codeController,
                  hintText: "Ex: 1234 1234 1234",
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if ((value ?? "").trim().isEmpty) {
                      return "Account number is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _FieldLabel(label: "Initial Balance"),
                const SizedBox(height: 8),
                _WalletTextField(
                  controller: balanceController,
                  hintText: "10000",
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if ((value ?? "").trim().isEmpty) {
                      return "Balance is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _FieldLabel(label: "Wallet Color"),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: colorOptions.map((hex) {
                    final selected = hex == selectedColorHex;
                    final color = _parseColor(hex);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedColorHex = hex;
                        });
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.22),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : _submitWallet,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(isSubmitting ? "Creating..." : "Create Wallet"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitWallet() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      final wallet = await AuthService.createWallet(
        name: titleController.text.trim(),
        accountNumber: codeController.text.trim(),
        balance: num.tryParse(balanceController.text.trim()) ?? 0,
        colorHex: selectedColorHex,
      );

      if (!mounted) return;
      Navigator.pop(context, wallet);
    } on ApiException catch (err) {
      if (!mounted) return;
      setState(() {
        errorMessage = err.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Failed to create wallet";
      });
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Color _parseColor(String value) {
    final hex = value.replaceFirst("#", "");
    final parsed = int.tryParse(hex.length == 6 ? "FF$hex" : hex, radix: 16);
    return parsed == null ? const Color(0xFF1E3A5F) : Color(parsed);
  }
}

class _WalletPreview extends StatelessWidget {
  final String title;
  final String accountNumber;
  final num balance;
  final String colorHex;

  const _WalletPreview({
    required this.title,
    required this.accountNumber,
    required this.balance,
    required this.colorHex,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = _parseColor(colorHex);
    final formatter = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp. ",
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [baseColor, Color.lerp(baseColor, Colors.black, 0.28)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.white),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title.isEmpty ? "Wallet Name" : title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            accountNumber.isEmpty ? "Account number" : accountNumber,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatter.format(balance),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String value) {
    final hex = value.replaceFirst("#", "");
    final parsed = int.tryParse(hex.length == 6 ? "FF$hex" : hex, radix: 16);
    return parsed == null ? const Color(0xFF1E3A5F) : Color(parsed);
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    );
  }
}

class _WalletTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _WalletTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFC107), width: 1.4),
        ),
      ),
    );
  }
}
