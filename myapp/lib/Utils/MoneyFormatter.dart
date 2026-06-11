import 'package:intl/intl.dart';
import 'package:myapp/Services/AppCurrencyService.dart';

class MoneyFormatter {
  MoneyFormatter._();

  static String format(num amount, {String? currency}) {
    final selected = (currency ?? AppCurrencyService.currency.value)
        .toUpperCase();
    if (selected == "USD") {
      return NumberFormat.currency(
        locale: "en_US",
        symbol: "\$",
        decimalDigits: 2,
      ).format(amount / AppCurrencyService.usdRate);
    }

    return NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp. ",
      decimalDigits: 0,
    ).format(amount);
  }
}
