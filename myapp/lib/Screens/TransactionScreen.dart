import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Models/TransactionModel.dart';
import 'package:myapp/Screens/TransactionDetailScreen.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:myapp/Widgets/HoverTapScale.dart';
import 'package:myapp/Widgets/TransactionCard.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

enum FilterType { all, income, expense, transfer }

class _TransactionScreenState extends State<TransactionScreen> {
  FilterType selectedFilter = FilterType.all;
  DateTime? selectedDate;
  List<TransactionModel> transactions = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = _groupByDay(transactions);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Transaction",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _pickDate,
                icon: Icon(
                  selectedDate == null
                      ? Icons.calendar_today_outlined
                      : Icons.event_available,
                ),
              ),
            ],
          ),
          if (selectedDate != null) ...[
            const SizedBox(height: 8),
            _DateFilterPill(
              date: selectedDate!,
              onClear: () {
                setState(() {
                  selectedDate = null;
                });
                _loadTransactions();
              },
            ),
          ],
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilter("All", FilterType.all),
                _buildFilter("Income", FilterType.income),
                _buildFilter("Expense", FilterType.expense),
                _buildFilter("Transfer", FilterType.transfer),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTransactions,
              child: _buildContent(groupedTransactions),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, List<TransactionModel>> grouped) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline, color: Colors.red.shade500, size: 36),
          const SizedBox(height: 10),
          Text(errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
              onPressed: _loadTransactions,
              child: const Text("Try Again"),
            ),
          ),
        ],
      );
    }

    if (grouped.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 140),
          Center(child: Text("There are no transactions")),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final day = grouped.keys.elementAt(groupIndex);
        final items = grouped[day]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(day),
            ...items.asMap().entries.map(
              (entry) => TransactionCard(
                transaction: entry.value,
                index: entry.key,
                onTap: () => _openDetail(entry.value.id),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadTransactions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetched = selectedDate == null
          ? await AuthService.getTransactions(type: _selectedTypeQuery())
          : await AuthService.getTransactionsByDate(
              DateFormat("yyyy-MM-dd").format(selectedDate!),
            );

      final filtered = selectedDate == null
          ? fetched
          : fetched.where((item) {
              final type = _selectedTypeQuery();
              return type == null || item.type == type;
            }).toList();

      if (!mounted) return;
      setState(() {
        transactions = filtered;
      });
    } on ApiException catch (err) {
      if (!mounted) return;
      setState(() {
        errorMessage = err.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Failed to load transactions";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
    });
    await _loadTransactions();
  }

  Future<void> _openDetail(String id) async {
    if (id.isEmpty) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transactionId: id),
      ),
    );
    if (changed == true) _loadTransactions();
  }

  String? _selectedTypeQuery() {
    switch (selectedFilter) {
      case FilterType.income:
        return "income";
      case FilterType.expense:
        return "expense";
      case FilterType.transfer:
        return "transfer";
      case FilterType.all:
        return null;
    }
  }

  Map<String, List<TransactionModel>> _groupByDay(
    List<TransactionModel> items,
  ) {
    final grouped = <String, List<TransactionModel>>{};

    for (final transaction in items) {
      final day = transaction.day.isEmpty
          ? DateFormat.yMMMd().format(transaction.date)
          : transaction.day.toUpperCase();
      grouped.putIfAbsent(day, () => []).add(transaction);
    }

    return grouped;
  }

  static Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildFilter(String text, FilterType type) {
    final isActive = selectedFilter == type;

    return HoverTapScale(
      onTap: () {
        setState(() {
          selectedFilter = type;
          selectedDate = null;
        });
        _loadTransactions();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.amber
              : Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DateFilterPill extends StatelessWidget {
  final DateTime date;
  final VoidCallback onClear;

  const _DateFilterPill({required this.date, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 14),
          const SizedBox(width: 8),
          Text(DateFormat.yMMMd().format(date)),
          const SizedBox(width: 8),
          HoverTapScale(
            onTap: onClear,
            borderRadius: BorderRadius.circular(999),
            child: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }
}
