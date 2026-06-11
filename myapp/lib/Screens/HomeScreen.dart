import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Models/NotificationHistoryModel.dart';
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
                  TransactionSection(
                    transactions: transactions,
                    onTransactionChanged: _loadHomeData,
                  ),
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Notification history",
      barrierColor: Colors.black.withOpacity(0.18),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _NotificationHistoryPopup(),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, -0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        );
      },
    );
  }
}

class _NotificationHistoryPopup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NotificationHistoryModel>>(
      future: AuthService.getNotificationHistory(),
      builder: (context, snapshot) {
        final histories = snapshot.data ?? [];

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.68,
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history_rounded),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Notification History",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Last 7 days reminder activity",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
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
              else if (histories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: Text("No notification history yet")),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: histories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _HistoryTile(history: histories[index]);
                    },
                  ),
                ),
            ],
          ),
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

class _HistoryTile extends StatelessWidget {
  final NotificationHistoryModel history;

  const _HistoryTile({required this.history});

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(history.timeScheduled);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_active, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  history.note.isEmpty ? history.daysActive : history.note,
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
                history.day.isEmpty
                    ? DateFormat.MMMd().format(history.createdAt)
                    : history.day,
                style: const TextStyle(
                  color: Color(0xFF64748B),
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
