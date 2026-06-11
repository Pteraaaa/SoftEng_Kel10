import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Models/CategoryModel.dart';
import 'package:myapp/Models/WalletModel.dart';
import 'package:myapp/Screens/CreateCategoryScreen.dart';
import 'package:myapp/Services/AppCurrencyService.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:myapp/Utils/MoneyFormatter.dart';
import 'package:myapp/Widgets/CategoryChip.dart';
import 'package:myapp/Widgets/HoverTapScale.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

enum TransactionType { expense, income, transfer }

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  List<WalletModel> wallets = [];
  List<CategoryModel> categories = [];
  WalletModel? selectedWallet;
  WalletModel? towardWallet;
  CategoryModel? selectedCategory;
  TransactionType selectedType = TransactionType.expense;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text("Add Transaction"),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypeSegment(
                        selectedType: selectedType,
                        onChanged: (type) {
                          setState(() {
                            selectedType = type;
                            selectedCategory = null;
                            towardWallet = null;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Amount",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          prefixText: "Rp. ",
                          hintText: "0",
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          final amount = num.tryParse(value ?? "");
                          if (amount == null || amount <= 0) {
                            return "Enter a valid amount";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      _TextInput(
                        controller: titleController,
                        label: "Title",
                        hint: selectedType == TransactionType.transfer
                            ? "Transfer to savings"
                            : "Dinner, salary, groceries",
                        icon: Icons.title,
                        validator: (value) {
                          if ((value ?? "").trim().isEmpty) {
                            return "Title is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _WalletDropdown(
                        label: selectedType == TransactionType.income
                            ? "To Wallet"
                            : "From Wallet",
                        wallets: wallets,
                        value: selectedWallet,
                        onChanged: (wallet) {
                          setState(() {
                            selectedWallet = wallet;
                          });
                        },
                      ),
                      if (selectedType == TransactionType.transfer) ...[
                        const SizedBox(height: 16),
                        _WalletDropdown(
                          label: "To Wallet",
                          wallets: wallets,
                          value: towardWallet,
                          onChanged: (wallet) {
                            setState(() {
                              towardWallet = wallet;
                            });
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 18),
                        _buildCategorySection(),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _PickerTile(
                              label: "Date",
                              value: DateFormat.yMMMd().format(selectedDate),
                              icon: Icons.calendar_today_outlined,
                              onTap: _pickDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PickerTile(
                              label: "Time",
                              value: selectedTime.format(context),
                              icon: Icons.access_time_outlined,
                              onTap: _pickTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _TextInput(
                        controller: noteController,
                        label: "Note",
                        hint: "Add a description...",
                        icon: Icons.notes_outlined,
                        minLines: 3,
                        maxLines: 5,
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBox(message: errorMessage!),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : _submit,
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            isSubmitting ? "Saving..." : "Save Transaction",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
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

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Category", style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...categories.map((category) {
              return CategoryChip(
                category: category,
                isSelected: selectedCategory?.id == category.id,
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                  });
                },
              );
            }),
            OutlinedButton.icon(
              onPressed: _openCreateCategory,
              icon: const Icon(Icons.add, size: 18),
              label: const Text("New Category"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.amber),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _loadFormData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        AuthService.getWallets(),
        AuthService.getCategories(),
      ]);

      if (!mounted) return;
      setState(() {
        wallets = results[0] as List<WalletModel>;
        categories = results[1] as List<CategoryModel>;
        selectedWallet = wallets.isEmpty ? null : wallets.first;
        selectedCategory = categories.isEmpty ? null : categories.first;
      });
    } on ApiException catch (err) {
      if (!mounted) return;
      setState(() {
        errorMessage = err.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Failed to load form data";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _openCreateCategory() async {
    final category = await Navigator.push<CategoryModel>(
      context,
      MaterialPageRoute(builder: (_) => const CreateCategoryScreen()),
    );

    if (category == null) return;

    setState(() {
      categories = [...categories, category];
      selectedCategory = category;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (selectedWallet == null) {
      setState(() => errorMessage = "Please select a wallet");
      return;
    }

    if (selectedType == TransactionType.transfer) {
      if (towardWallet == null) {
        setState(() => errorMessage = "Please select destination wallet");
        return;
      }
      if (towardWallet!.id == selectedWallet!.id) {
        setState(() => errorMessage = "Wallets cannot be the same");
        return;
      }
    } else if (selectedCategory == null) {
      setState(() => errorMessage = "Please select a category");
      return;
    }

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      final amount = num.parse(amountController.text.trim());
      final transactionDate = _transactionDate();
      final title = titleController.text.trim();
      final note = noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim();

      if (selectedType == TransactionType.transfer) {
        await AuthService.createTransferTransaction(
          amount: amount,
          fromWalletId: selectedWallet!.id,
          toWalletId: towardWallet!.id,
          transactionDate: transactionDate,
          title: title,
          note: note,
        );
      } else {
        await AuthService.createIncomeExpenseTransaction(
          type: selectedType == TransactionType.income ? "income" : "expense",
          amount: amount,
          categoryId: selectedCategory!.id,
          walletId: selectedWallet!.id,
          transactionDate: transactionDate,
          title: title,
          note: note,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (err) {
      if (!mounted) return;
      setState(() => errorMessage = err.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = "Failed to save transaction");
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  String _transactionDate() {
    final combined = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    return DateFormat("yyyy-MM-dd HH:mm:ss").format(combined);
  }
}

class _TypeSegment extends StatelessWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onChanged;

  const _TypeSegment({required this.selectedType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _button(context, "Expense", TransactionType.expense),
          _button(context, "Income", TransactionType.income),
          _button(context, "Transfer", TransactionType.transfer),
        ],
      ),
    );
  }

  Widget _button(BuildContext context, String text, TransactionType type) {
    final isSelected = selectedType == type;
    return Expanded(
      child: HoverTapScale(
        onTap: () => onChanged(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).cardColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletDropdown extends StatelessWidget {
  final String label;
  final List<WalletModel> wallets;
  final WalletModel? value;
  final ValueChanged<WalletModel?> onChanged;

  const _WalletDropdown({
    required this.label,
    required this.wallets,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppCurrencyService.currency,
      builder: (context, currency, _) {
        return DropdownButtonFormField<WalletModel>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          items: wallets.map((wallet) {
            return DropdownMenuItem(
              value: wallet,
              child: Text(
                "${wallet.title} (${MoneyFormatter.format(wallet.balance, currency: currency)})",
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (wallet) =>
              wallet == null ? "Please select a wallet" : null,
        );
      },
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int? minLines;
  final int maxLines;
  final String? Function(String?)? validator;

  const _TextInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.minLines,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HoverTapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade700)),
    );
  }
}
