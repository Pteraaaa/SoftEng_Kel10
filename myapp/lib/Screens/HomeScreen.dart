import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Models/ReminderModel.dart';
import 'package:myapp/Models/TransactionModel.dart';
import 'package:myapp/Models/UsersModel.dart';
import 'package:myapp/Models/WalletModel.dart';
import 'package:myapp/Screens/AddWalletScreen.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:myapp/Widgets/InfoCard.dart';
import 'package:myapp/Widgets/TransactionTile.dart';
import 'package:myapp/Widgets/WalletSection.dart';
import '../Widgets/TotalBalance.dart';

class HomeScreen extends StatefulWidget {
  final UsersModel user;
  const HomeScreen({required this.user, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<WalletModel> wallets = [];
  List<TransactionModel> transactions = [];
  num monthlyIncome = 0;
  num monthlyExpense = 0;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome Back",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.user.username,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _openReminders,
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 90),
                    child: CircularProgressIndicator(),
                  )
                else if (errorMessage != null)
                  _HomeError(message: errorMessage!, onRetry: _loadHomeData)
                else ...[
                  TotalBalance(balance: totalBalance),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Infocard(
                        title: "Income",
                        amount: monthlyIncome,
                        icon: Icons.arrow_downward,
                        iconColor: Colors.green,
                        backgroundColor: Colors.green[100]!,
                      ),
                      const SizedBox(width: 10),
                      Infocard(
                        title: "Expenses",
                        amount: monthlyExpense,
                        icon: Icons.arrow_upward,
                        iconColor: Colors.red,
                        backgroundColor: Colors.red[100]!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  WalletSection(wallets: wallets, onAddWallet: _addWallet),
                  const SizedBox(height: 8),
                  TransactionSection(transactions: transactions),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  num get totalBalance {
    return wallets.fold<num>(0, (total, wallet) => total + wallet.balance);
  }

  Future<void> _loadHomeData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedWallets = await _retry(AuthService.getWallets);
      final recentTransactions = await _optional(
        () => _retry(AuthService.getRecentTransactions),
        fallback: <TransactionModel>[],
      );
      final allTransactions = await _optional(
        () => _retry(AuthService.getTransactions),
        fallback: <TransactionModel>[],
      );
      final summary = _monthlySummary(allTransactions);

      if (!mounted) return;
      setState(() {
        wallets = fetchedWallets;
        transactions = recentTransactions;
        monthlyIncome = summary.income;
        monthlyExpense = summary.expense;
      });
    } on ApiException catch (err) {
      if (!mounted) return;
      setState(() {
        errorMessage = err.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Failed to load home data";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<T> _retry<T>(Future<T> Function() action, {int attempts = 3}) async {
    Object? latestError;

    for (var i = 0; i < attempts; i++) {
      try {
        return await action();
      } catch (err) {
        latestError = err;
        if (i < attempts - 1) {
          await Future.delayed(Duration(milliseconds: 450 * (i + 1)));
        }
      }
    }

    throw latestError ?? ApiException("Failed to load home data");
  }

  Future<T> _optional<T>(
    Future<T> Function() action, {
    required T fallback,
  }) async {
    try {
      return await action();
    } catch (_) {
      return fallback;
    }
  }

  _MonthlySummary _monthlySummary(List<TransactionModel> items) {
    final since = DateTime.now().subtract(const Duration(days: 30));
    num income = 0;
    num expense = 0;

    for (final transaction in items) {
      if (transaction.date.isBefore(since)) continue;

      if (transaction.type == "income") {
        income += transaction.amount;
      } else if (transaction.type == "expense") {
        expense += transaction.amount;
      }
    }

    return _MonthlySummary(income: income, expense: expense);
  }

  Future<void> _addWallet() async {
    final result = await Navigator.push<WalletModel>(
      context,
      MaterialPageRoute(builder: (context) => const AddWalletScreen()),
    );

    if (result != null) {
      await _loadHomeData();
    }
  }

  Future<void> _openReminders() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<List<ReminderModel>>(
          future: AuthService.getReminders(),
          builder: (context, snapshot) {
            final reminders = snapshot.data ?? [];

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_active_outlined),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Recent Reminders",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Upcoming wallet and transaction alerts",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        "Failed to load reminders",
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    )
                  else if (reminders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: Text("No reminders yet")),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: reminders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _ReminderTile(reminder: reminders[index]);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MonthlySummary {
  final num income;
  final num expense;

  const _MonthlySummary({required this.income, required this.expense});
}

class _HomeError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _HomeError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade500, size: 36),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text("Try Again")),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final ReminderModel reminder;

  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(reminder.timeScheduled);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: reminder.isActive ? const Color(0xFFFFF8E1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: reminder.isActive
              ? const Color(0xFFFFC107).withOpacity(0.45)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: reminder.isActive ? const Color(0xFFFFC107) : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.alarm, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  reminder.note.isEmpty ? reminder.daysActive : reminder.note,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                reminder.isActive ? "Active" : "Off",
                style: TextStyle(
                  color: reminder.isActive
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(String value) {
    try {
      return DateFormat("HH:mm").format(DateFormat("HH:mm:ss").parse(value));
    } catch (_) {
      return value;
    }
  }
}
