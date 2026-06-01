import 'package:flutter/material.dart';
import 'package:myapp/Models/UsersModel.dart';
import 'package:myapp/Widgets/NavBar.dart';
import 'HomeScreen.dart';
import 'AnalyticsScreen.dart';
import 'ProfileScreen.dart';
import 'TransactionScreen.dart';
import 'AddTransactionScreen.dart';

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
        return TransactionScreen();
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
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Choose Option",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    ListTile(
                      leading: const Icon(Icons.attach_money),
                      title: const Text("Transaction"),
                      onTap: () {
                        Navigator.pop(context);

                        // Navigate or do something
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTransactionScreen(),
                          ),
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text("Notification"),
                      onTap: () {
                        Navigator.pop(context);

                        // Navigate or do something
                        print("Notification Selected");
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },

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
