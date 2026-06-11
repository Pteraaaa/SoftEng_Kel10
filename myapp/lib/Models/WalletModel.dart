class WalletModel {
  final String id;
  final String title;
  final String code;
  final num balance;
  final String colorHex;

  WalletModel({
    this.id = "",
    required this.title,
    required this.code,
    required this.balance,
    this.colorHex = "#1E3A5F",
  });

  String get name => title;

  factory WalletModel.fromApi(Map<String, dynamic> data) {
    return WalletModel(
      id: data["id"]?.toString() ?? data["walletId"]?.toString() ?? "",
      title: data["name"]?.toString() ?? "",
      code: data["account_number"]?.toString() ?? "",
      balance: _toNum(data["balance"]),
      colorHex: data["color_hex"]?.toString() ?? "#1E3A5F",
    );
  }

  static num _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? "") ?? 0;
  }
}
