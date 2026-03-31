import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const NavBar({Key? key, required this.selectedIndex, required this.onTap})
    : super(key: key);

  Widget _item(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.amber : Colors.grey),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.amber.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
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
