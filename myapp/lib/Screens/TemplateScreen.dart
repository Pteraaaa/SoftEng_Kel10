import 'package:flutter/material.dart';
import 'package:myapp/Models/UsersModel.dart';
import 'package:myapp/Widgets/NavBar.dart';
import 'HomeScreen.dart';
import 'AnalyticsScreen.dart';
import 'ProfileScreen.dart';
import 'TransactionScreen.dart';

class TemplateScreen extends StatefulWidget {
  final UsersModel user;
  const TemplateScreen({required this.user, super.key});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  int _selectedIndex = 0;

  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return HomeScreen(user: widget.user);
      case 1:
        return TransactionScreen();
      case 2:
        return AnalyticsScreen();
      case 3:
        return ProfileScreen();
      default:
        return HomeScreen(user: widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
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
}
