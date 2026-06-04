import 'package:flutter/material.dart';
import 'package:myapp/Screens/AuthCallbackScreen.dart';
import 'package:myapp/Screens/AuthScreen.dart';
import 'package:myapp/Screens/TemplateScreen.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:myapp/Services/TokenStorage.dart';

void main() {
  runApp(const MainApp());
}

const appBackgroundColor = Color(0xFFFAF9F6);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authCode = AuthCallbackUri.extractAuthCode(Uri.base);

    return MaterialApp(
      title: "Pocket Log",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: appBackgroundColor,
        canvasColor: appBackgroundColor,
      ),
      home: authCode == null
          ? const AuthGate()
          : AuthCallbackScreen(authCode: authCode),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<Widget> _initialScreen;

  @override
  void initState() {
    super.initState();
    _initialScreen = _loadInitialScreen();
  }

  Future<Widget> _loadInitialScreen() async {
    final accessToken = await TokenStorage.getAccessToken();
    final refreshToken = await TokenStorage.getRefreshToken();

    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      return const AuthScreen();
    }

    try {
      final user = await AuthService.getMeWithRefresh();
      return TemplateScreen(user: user);
    } catch (_) {
      await TokenStorage.clear();
      return const AuthScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreen,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return snapshot.data!;
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
