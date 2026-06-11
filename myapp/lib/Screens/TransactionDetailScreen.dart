import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Models/CategoryModel.dart';
import 'package:myapp/Models/TransactionModel.dart';
import 'package:myapp/Models/WalletModel.dart';
import 'package:myapp/Services/AppCurrencyService.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:myapp/Utils/MoneyFormatter.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? transaction;
  bool isLoading = true;
  String? errorMessage;
  bool _changed = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          title: const Text(
            "Transaction Detail",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? _ErrorState(message: errorMessage!, onRetry: _loadDetail)
            : _buildBody(transaction!),
      ),
    );
  }

  Widget _buildBody(TransactionModel item) {
    final isTransfer = item.type == "transfer";
    final color = isTransfer
        ? _parseColor(item.toWalletColorHex, fallback: const Color(0xFF6366F1))
        : _parseColor(item.colorHex, fallback: Colors.amber);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.85), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconFor(item), color: Colors.white, size: 34),
                ),
                const SizedBox(height: 14),
                Text(
                  item.title.isEmpty ? "Untitled" : item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                if (!isTransfer) ...[
                  ValueListenableBuilder<String>(
                    valueListenable: AppCurrencyService.currency,
                    builder: (context, currency, _) {
                      return Text(
                        "${item.isExpense ? '-' : '+'}${MoneyFormatter.format(item.amount, currency: currency)}",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${item.type.toUpperCase()} - ${item.category}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ] else ...[
                  ValueListenableBuilder<String>(
                    valueListenable: AppCurrencyService.currency,
                    builder: (context, currency, _) {
                      return Text(
                        MoneyFormatter.format(item.amount, currency: currency),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "TRANSFER",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                children: [
                  // Transfer wallets panel
                  if (isTransfer)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _WalletNode(
                              label: "From",
                              name: item.fromWalletName,
                              colorHex: item.fromWalletColorHex,
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: color,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: _WalletNode(
                              label: "To",
                              name: item.toWalletName,
                              colorHex: item.toWalletColorHex,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _InfoCard(
                      color: color,
                      rows: [
                        _InfoRow(
                          icon: Icons.category_outlined,
                          label: "Category",
                          value: item.category,
                        ),
                        _InfoRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: item.isExpense ? "From Wallet" : "To Wallet",
                          value: item.isExpense
                              ? item.fromWalletName
                              : item.toWalletName,
                        ),
                        _InfoRow(
                          icon: Icons.payments_outlined,
                          label: "Amount",
                          value: MoneyFormatter.format(item.amount),
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    color: color,
                    rows: [
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: "Date",
                        value: DateFormat.yMMMMd().format(item.date),
                      ),
                      _InfoRow(
                        icon: Icons.access_time_rounded,
                        label: "Time",
                        value: DateFormat.Hm().format(item.date),
                      ),
                      _InfoRow(
                        icon: Icons.today_outlined,
                        label: "Day",
                        value: item.day.isEmpty ? "-" : item.day,
                      ),
                      _InfoRow(
                        icon: Icons.notes_outlined,
                        label: "Note",
                        value: item.note.isEmpty ? "-" : item.note,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isDeleting ? null : _confirmDelete,
                          icon: _isDeleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                          label: const Text(
                            "Delete",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openEdit(item),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Edit",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final detail = await AuthService.getTransactionDetail(
        widget.transactionId,
      );
      if (!mounted) return;
      setState(() {
        transaction = detail;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = "Failed to load transaction detail");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Transaction",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this transaction? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final transactionId = transaction!.id.isEmpty
        ? widget.transactionId
        : transaction!.id;
    if (transactionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Transaction ID is missing"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isDeleting = true);
    try {
      await AuthService.deleteTransaction(transactionId);
      if (!mounted) return;
      _changed = true;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to delete"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _openEdit(TransactionModel item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTransactionScreen(
          transaction: item,
          transactionId: widget.transactionId,
        ),
      ),
    );
    if (changed == true) {
      _changed = true;
      await _loadDetail();
    }
  }

  IconData _iconFor(TransactionModel item) {
    if (item.type == "transfer") return Icons.swap_horiz_rounded;
    switch (item.iconName) {
      case "ic_restaurant":
      case "restaurant":
        return Icons.restaurant;
      case "ic_shopping_cart":
      case "shopping_cart":
        return Icons.shopping_cart;
      case "ic_work":
      case "work":
        return Icons.work;
      case "ic_movie":
      case "movie":
        return Icons.movie;
      case "ic_directions_car":
      case "transport":
        return Icons.directions_car;
      case "ic_payments":
      case "income":
        return Icons.payments;
      default:
        return Icons.payments_outlined;
    }
  }

  Color _parseColor(String value, {required Color fallback}) {
    final hex = value.replaceFirst("#", "");
    final parsed = int.tryParse(hex.length == 6 ? "FF$hex" : hex, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}

// ─── Info Card ────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final Color color;
  final List<_InfoRow> rows;
  const _InfoCard({required this.color, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(e.value.icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      e.value.label,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        e.value.value.isEmpty ? "-" : e.value.value,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: Colors.grey.shade100,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}

// ─── Wallet Node ──────────────────────────────────────────────
class _WalletNode extends StatelessWidget {
  final String label, name, colorHex;
  const _WalletNode({
    required this.label,
    required this.name,
    required this.colorHex,
  });

  @override
  Widget build(BuildContext context) {
    final hex = colorHex.replaceFirst("#", "");
    final parsed = int.tryParse(hex.length == 6 ? "FF$hex" : hex, radix: 16);
    final color = parsed == null ? Colors.amber : Color(parsed);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.account_balance_wallet_rounded, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          name.isEmpty ? "Wallet" : name,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ─── Error State ──────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text("Try Again")),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Transaction Screen ──────────────────────────────────
class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;
  final String transactionId;
  const EditTransactionScreen({
    super.key,
    required this.transaction,
    required this.transactionId,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController titleCtrl;
  late TextEditingController amountCtrl;
  late TextEditingController noteCtrl;

  List<WalletModel> wallets = [];
  List<CategoryModel> categories = [];
  WalletModel? fromWallet;
  WalletModel? toWallet;
  CategoryModel? selectedCategory;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;

  bool get isTransfer => widget.transaction.type == "transfer";

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.transaction.title);
    amountCtrl = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(0),
    );
    noteCtrl = TextEditingController(text: widget.transaction.note);
    selectedDate = widget.transaction.date;
    selectedTime = TimeOfDay(
      hour: widget.transaction.date.hour,
      minute: widget.transaction.date.minute,
    );
    _loadData();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        AuthService.getWallets(),
        AuthService.getCategories(),
      ]);
      if (!mounted) return;
      final ws = results[0] as List<WalletModel>;
      final cs = results[1] as List<CategoryModel>;
      final primaryWalletName = widget.transaction.type == "income"
          ? widget.transaction.toWalletName
          : widget.transaction.fromWalletName;
      setState(() {
        wallets = ws;
        categories = cs;
        fromWallet = ws.isEmpty
            ? null
            : ws.firstWhere(
                (w) => w.name == primaryWalletName,
                orElse: () => ws.first,
              );
        toWallet = ws.isEmpty
            ? null
            : ws.firstWhere(
                (w) => w.name == widget.transaction.toWalletName,
                orElse: () => ws.last,
              );
        selectedCategory = cs.isEmpty
            ? null
            : cs.firstWhere(
                (c) => c.title == widget.transaction.category,
                orElse: () => cs.first,
              );
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load data";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit ${isTransfer ? 'Transfer' : widget.transaction.type.capitalize()}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(
                      "Title",
                      TextFormField(
                        controller: titleCtrl,
                        decoration: _dec("Title", Icons.title),
                        validator: (v) =>
                            (v ?? "").trim().isEmpty ? "Required" : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      "Amount",
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _dec(
                          "Amount",
                          Icons.payments_outlined,
                          prefix: "Rp ",
                        ),
                        validator: (v) => (num.tryParse(v ?? "") ?? 0) <= 0
                            ? "Enter valid amount"
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (isTransfer) ...[
                      _field(
                        "From Wallet",
                        _walletDropdown(
                          "From Wallet",
                          fromWallet,
                          (w) => setState(() => fromWallet = w),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _field(
                        "To Wallet",
                        _walletDropdown(
                          "To Wallet",
                          toWallet,
                          (w) => setState(() => toWallet = w),
                        ),
                      ),
                    ] else ...[
                      _field(
                        widget.transaction.isExpense
                            ? "From Wallet"
                            : "To Wallet",
                        _walletDropdown(
                          widget.transaction.isExpense
                              ? "From Wallet"
                              : "To Wallet",
                          fromWallet,
                          (w) => setState(() => fromWallet = w),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _field(
                        "Category",
                        DropdownButtonFormField<CategoryModel>(
                          value: selectedCategory,
                          decoration: _dec("Category", Icons.category_outlined),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.title),
                                ),
                              )
                              .toList(),
                          onChanged: (c) =>
                              setState(() => selectedCategory = c),
                          validator: (v) =>
                              v == null ? "Select category" : null,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _pickerTile(
                            "Date",
                            DateFormat.yMMMd().format(selectedDate),
                            Icons.calendar_today_outlined,
                            _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _pickerTile(
                            "Time",
                            selectedTime.format(context),
                            Icons.access_time_rounded,
                            _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _field(
                      "Note",
                      TextFormField(
                        controller: noteCtrl,
                        minLines: 3,
                        maxLines: 5,
                        decoration: _dec(
                          "Note (optional)",
                          Icons.notes_outlined,
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
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
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                              ),
                        label: Text(
                          isSubmitting ? "Saving..." : "Save Changes",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _field(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _dec(String label, IconData icon, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _walletDropdown(
    String label,
    WalletModel? value,
    ValueChanged<WalletModel?> onChanged,
  ) {
    return ValueListenableBuilder<String>(
      valueListenable: AppCurrencyService.currency,
      builder: (context, currency, _) {
        return DropdownButtonFormField<WalletModel>(
          value: value,
          decoration: _dec(label, Icons.account_balance_wallet_outlined),
          items: wallets
              .map(
                (w) => DropdownMenuItem(
                  value: w,
                  child: Text(
                    "${w.title} (${MoneyFormatter.format(w.balance, currency: currency)})",
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? "Select wallet" : null,
        );
      },
    );
  }

  Widget _pickerTile(
    String label,
    String val,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
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
                    val,
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

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (p != null) setState(() => selectedDate = p);
  }

  Future<void> _pickTime() async {
    final p = await showTimePicker(context: context, initialTime: selectedTime);
    if (p != null) setState(() => selectedTime = p);
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });
    try {
      final amount = num.parse(amountCtrl.text.trim());
      final combined = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      final transactionDate = DateFormat(
        "yyyy-MM-dd HH:mm:ss",
      ).format(combined);
      final title = titleCtrl.text.trim();
      final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
      final id = widget.transaction.id.isEmpty
          ? widget.transactionId
          : widget.transaction.id;
      if (id.isEmpty) {
        setState(() => errorMessage = "Transaction ID is missing");
        return;
      }
      if (isTransfer) {
        await AuthService.editTransferTransaction(
          id: id,
          amount: amount,
          fromWalletId: fromWallet!.id,
          toWalletId: toWallet!.id,
          transactionDate: transactionDate,
          title: title,
          note: note,
        );
      } else {
        await AuthService.editIncomeExpenseTransaction(
          id: id,
          type: widget.transaction.type,
          amount: amount,
          categoryId: selectedCategory!.id,
          walletId: fromWallet!.id,
          transactionDate: transactionDate,
          title: title,
          note: note,
        );
      }
      if (!mounted) return;
      await Navigator.maybePop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = "Failed to save changes");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }
}

extension StringExt on String {
  String capitalize() =>
      isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}
