import 'package:flutter/material.dart';
import 'package:myapp/Widgets/HoverTapScale.dart';

class NavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const NavBar({Key? key, required this.selectedIndex, required this.onTap})
    : super(key: key);

  Widget _item(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;

    return HoverTapScale(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      hoverScale: 1.05,
      pressScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.08 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Icon(icon, color: isSelected ? Colors.amber : Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.amber.shade700
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Theme.of(context).cardColor,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _item(Icons.home, "Home", 0),
            _item(Icons.receipt, "Transactions", 1),

            const SizedBox(width: 40),

            _item(Icons.bar_chart, "Analytics", 2),
            _item(Icons.person, "Profile", 3),
          ],
        ),
      ),
    );
  }
}
