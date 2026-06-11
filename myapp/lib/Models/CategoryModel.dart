import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String title;
  final IconData icon;
  final String iconName;
  final String colorHex;

  CategoryModel({
    this.id = "",
    required this.title,
    required this.icon,
    this.iconName = "ic_payments",
    this.colorHex = "#9E9E9E",
  });

  factory CategoryModel.fromApi(Map<String, dynamic> data) {
    final iconName = data["icon_url"]?.toString() ?? "ic_payments";
    return CategoryModel(
      id: data["id"]?.toString() ?? "",
      title: data["name"]?.toString() ?? "Category",
      icon: iconFromName(iconName),
      iconName: iconName,
      colorHex: data["color_hex"]?.toString() ?? "#9E9E9E",
    );
  }

  static IconData iconFromName(String value) {
    switch (value) {
      case "ic_restaurant":
      case "restaurant":
        return Icons.restaurant_outlined;
      case "ic_shopping_cart":
      case "shopping_cart":
        return Icons.shopping_cart_outlined;
      case "ic_directions_car":
      case "transport":
        return Icons.directions_car_outlined;
      case "ic_home":
        return Icons.home_outlined;
      case "ic_movie":
      case "movie":
        return Icons.movie_outlined;
      case "ic_work":
      case "work":
        return Icons.work_outline;
      case "ic_swap_horiz":
        return Icons.swap_horiz;
      case "ic_school":
        return Icons.school_outlined;
      case "ic_savings":
        return Icons.savings_outlined;
      case "ic_medical":
        return Icons.medical_services_outlined;
      case "ic_flight":
        return Icons.flight_outlined;
      default:
        return Icons.payments_outlined;
    }
  }
}
