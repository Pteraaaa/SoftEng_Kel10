class TransactionModel {
  final String id;
  final String title;
  final String category;
  final num amount;
  final DateTime date;
  final bool isExpense;
  final String note;
  final String iconName;
  final String colorHex;
  final String type;
  final String day;
  final String fromWalletName;
  final String fromWalletColorHex;
  final String toWalletName;
  final String toWalletColorHex;

  const TransactionModel({
    this.id = "",
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isExpense,
    this.note = "",
    this.iconName = "",
    this.colorHex = "#9E9E9E",
    this.type = "expense",
    this.day = "",
    this.fromWalletName = "",
    this.fromWalletColorHex = "",
    this.toWalletName = "",
    this.toWalletColorHex = "",
  });

  factory TransactionModel.fromApi(Map<String, dynamic> data) {
    final type = data["type"]?.toString() ?? "expense";

    return TransactionModel(
      id: data["id"]?.toString() ?? "",
      title: data["title"]?.toString() ?? "",
      category: data["category_name"]?.toString() ?? "Uncategorized",
      amount: _toNum(data["amount"]),
      date:
          DateTime.tryParse(data["transaction_date"]?.toString() ?? "") ??
          DateTime.now(),
      isExpense: type == "expense",
      note: data["note"]?.toString() ?? "",
      iconName: data["category_icon_url"]?.toString() ?? "",
      colorHex: data["category_color_hex"]?.toString() ?? "#9E9E9E",
      type: type,
      day: data["day"]?.toString() ?? "",
      fromWalletName: data["from_wallet_name"]?.toString() ?? "",
      fromWalletColorHex: data["from_wallet_color_hex"]?.toString() ?? "",
      toWalletName: data["to_wallet_name"]?.toString() ?? "",
      toWalletColorHex: data["to_wallet_color_hex"]?.toString() ?? "",
    );
  }

  static num _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? "") ?? 0;
  }
}
