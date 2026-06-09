import 'package:flutter/material.dart';
import 'package:myapp/Models/UsersModel.dart';
import 'package:myapp/Widgets/NavBar.dart';
import 'HomeScreen.dart';
import 'AnalyticsScreen.dart';
import 'ProfileScreen.dart';
import 'TransactionScreen.dart';
import 'AddTransactionScreen.dart';
import 'AddNotificationScreen.dart';

class TemplateScreen extends StatefulWidget {
  final UsersModel user;
  const TemplateScreen({required this.user, super.key});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  int _selectedIndex = 0;
  late UsersModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return HomeScreen(user: _user);
      case 1:
        return const TransactionScreen();
      case 2:
        return AnalyticsScreen();
      case 3:
        return ProfileScreen(
          user: _user,
          onUserChanged: (user) {
            setState(() {
              _user = user;
            });
          },
        );
      default:
        return HomeScreen(user: _user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(),

      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateMenu,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: NavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Future<void> _openCreateMenu() async {
    final action = await showModalBottomSheet<_CreateAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Create New",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Add a transaction or schedule a reminder.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 18),
              _CreateMenuItem(
                icon: Icons.receipt_long_outlined,
                title: "Transaction",
                subtitle: "Income, expense, or wallet transfer",
                color: Colors.amber,
                onTap: () => Navigator.pop(context, _CreateAction.transaction),
              ),
              const SizedBox(height: 12),
              _CreateMenuItem(
                icon: Icons.notifications_active_outlined,
                title: "Notification",
                subtitle: "Create a wallet reminder",
                color: const Color(0xFF2563EB),
                onTap: () => Navigator.pop(context, _CreateAction.notification),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == _CreateAction.transaction) {
      final created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
      );
      if (created == true && mounted) {
        setState(() {});
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddNotificationScreen()),
    );
  }
}

enum _CreateAction { transaction, notification }

class _CreateMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CreateMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
