import 'package:flutter/material.dart';
import 'package:myapp/Models/CategoryModel.dart';

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
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white,

          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey.shade300,
          ),

          borderRadius: BorderRadius.circular(30),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 18,

              color: isSelected ? Colors.white : Colors.black,
            ),

            const SizedBox(width: 8),

            Text(
              category.title,

              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,

                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
