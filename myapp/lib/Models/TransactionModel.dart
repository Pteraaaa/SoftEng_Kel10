class TransactionModel {
  final String title;
  final String category;
  final int amount;
  final DateTime date;
  final bool isExpense;

  const TransactionModel({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isExpense,
  });
}
