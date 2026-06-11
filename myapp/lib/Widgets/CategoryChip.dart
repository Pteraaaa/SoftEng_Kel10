import 'package:flutter/material.dart';
import 'package:myapp/Models/CategoryModel.dart';
import 'package:myapp/Widgets/HoverTapScale.dart';

class CategoryChip extends StatelessWidget {
  final CategoryModel category;

  final bool isSelected;

  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.colorHex);

    return HoverTapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        decoration: BoxDecoration(
          color: isSelected ? color : Theme.of(context).cardColor,

          border: Border.all(color: isSelected ? color : Colors.grey.shade300),

          borderRadius: BorderRadius.circular(30),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 18,

              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),

            const SizedBox(width: 8),

            Text(
              category.title,

              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,

                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String value) {
    final hex = value.replaceFirst("#", "");
    final parsed = int.tryParse(hex.length == 6 ? "FF$hex" : hex, radix: 16);
    return parsed == null ? Colors.amber : Color(parsed);
  }
}
