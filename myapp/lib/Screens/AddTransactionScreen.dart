import 'package:flutter/material.dart';
import 'package:myapp/Models/WalletModel.dart';
import 'package:myapp/Models/CategoryModel.dart';
import 'package:myapp/Widgets/CategoryChip.dart';
import 'CreateCategoryScreen.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

enum TransactionType { expense, income, transfer }

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final List<WalletModel> wallets = [
    WalletModel(title: "BCA", code: "abcd", balance: 10000),
    WalletModel(title: "Danamon", code: "edfg", balance: 200000),
  ];

  final List<CategoryModel> categories = [
    CategoryModel(title: "Food", icon: Icons.restaurant),
    CategoryModel(title: "Transport", icon: Icons.directions_car),
    CategoryModel(title: "Entertainment", icon: Icons.tv),
  ];

  WalletModel? selectedWallet;
  WalletModel? towardWallet;
  final _formkey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  TransactionType selectedType = TransactionType.expense;

  CategoryModel? selectedCategory;
  Widget buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text("Category"),

        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,

          children: [
            ...categories.map((category) {
              return CategoryChip(
                category: category,

                isSelected: selectedCategory == category,

                onTap: () {
                  setState(() {
                    selectedCategory = category;
                  });
                },
              );
            }),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const CreateCategoryScreen(),
                  ),
                );
              },

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange),

                  borderRadius: BorderRadius.circular(30),
                ),

                child: const Text("+ New Category"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    dateController.text = DateFormat('dd MMMM yyyy').format(DateTime.now());
    final now = TimeOfDay.now();

    timeController.text =
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formkey,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      ),
                      const Text(
                        "Add Transaction",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_formkey.currentState!.validate()) {
                            print("Valid");
                          }
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        buildTypeButton("Expense", TransactionType.expense),
                        buildTypeButton("Income", TransactionType.income),
                        buildTypeButton("Transfer", TransactionType.transfer),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text("Amount"),

                  const SizedBox(height: 10),

                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,

                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),

                    decoration: const InputDecoration(
                      hintText: "Rp.XXX",

                      prefixStyle: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),

                      border: InputBorder.none,
                    ),

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Amount is required";
                      }

                      final number = int.tryParse(value);

                      if (number == null) {
                        return "Enter a valid number";
                      }

                      if (number <= 0) {
                        return "Amount must be greater than 0";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  DropdownButtonFormField<WalletModel>(
                    value: selectedWallet,

                    decoration: InputDecoration(
                      labelText: "From Wallet",

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    items: wallets.map((wallet) {
                      return DropdownMenuItem(
                        value: wallet,

                        child: Text("${wallet.title} (Rp${wallet.balance})"),
                      );
                    }).toList(),

                    onChanged: (wallet) {
                      setState(() {
                        selectedWallet = wallet;
                      });
                    },

                    validator: (value) {
                      if (value == null) {
                        return "Please select a wallet";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  /// CONDITIONAL PART
                  if (selectedType == TransactionType.transfer)
                    DropdownButtonFormField<WalletModel>(
                      value: towardWallet,

                      decoration: InputDecoration(
                        labelText: "To Wallet",

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      items: wallets.map((wallet) {
                        return DropdownMenuItem(
                          value: wallet,

                          child: Text("${wallet.title} (Rp${wallet.balance})"),
                        );
                      }).toList(),

                      onChanged: (wallet) {
                        setState(() {
                          towardWallet = wallet;
                        });
                      },

                      validator: (value) {
                        if (value == null) {
                          return "Please select a wallet";
                        }

                        if (towardWallet == selectedWallet) {
                          return "The wallets shouldn't be the same";
                        }

                        return null;
                      },
                    )
                  else
                    buildCategorySection(),

                  const SizedBox(height: 20),

                  /// DATE
                  TextFormField(
                    controller: dateController,

                    readOnly: true,

                    decoration: InputDecoration(
                      labelText: "Date",

                      suffixIcon: const Icon(Icons.calendar_today_outlined),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,

                        initialDate: DateTime.now(),

                        firstDate: DateTime(2020),

                        lastDate: DateTime(2100),
                      );

                      if (pickedDate != null) {
                        setState(() {
                          dateController.text = DateFormat(
                            'dd MMMM yyyy',
                          ).format(pickedDate);
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  /// TIME
                  TextFormField(
                    controller: timeController,

                    readOnly: true,

                    decoration: InputDecoration(
                      labelText: "Time",

                      suffixIcon: const Icon(Icons.access_time_outlined),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,

                        initialTime: TimeOfDay.now(),
                      );

                      if (pickedTime != null) {
                        setState(() {
                          timeController.text = pickedTime.format(context);
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  /// NOTE
                  TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Add a description...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTypeButton(String text, TransactionType type) {
    final isSelected = selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedType = type;
          });
        },

        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),

          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CATEGORY SECTION
Widget buildCategorySection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Category"),

      const SizedBox(height: 10),

      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          buildCategoryChip("Dining Out"),
          buildCategoryChip("Transport"),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.orange,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text("+ New Category"),
          ),
        ],
      ),
    ],
  );
}

Widget buildCategoryChip(String title) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(title),
  );
}
