import 'package:flutter/material.dart';
import 'package:myapp/Screens/AuthScreen.dart';
import 'package:myapp/Screens/TemplateScreen.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:myapp/Services/TokenStorage.dart';

class AuthCallbackScreen extends StatefulWidget {
  final String authCode;

  const AuthCallbackScreen({required this.authCode, super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    exchangeToken();
  }

  Future<void> exchangeToken() async {
    try {
      final result = await AuthService.exchangeGoogleAuthCode(widget.authCode);

      await TokenStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );

      final user = await AuthService.getMeWithRefresh();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TemplateScreen(user: user)),
      );
    } catch (error) {
      await TokenStorage.clear();

      if (!mounted) return;

      if (error is TokenExpiredException) {
        await showDialog<void>(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text("Session Expired"),
              content: const Text("Session Expired please login again"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );

        if (!mounted) return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AuthScreen(
            initialLoginError: error is TokenExpiredException
                ? null
                : error.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class AuthCallbackUri {
  static String? extractAuthCode(Uri uri) {
    final directAuthCode = uri.queryParameters["authCode"];
    if (directAuthCode != null && directAuthCode.isNotEmpty) {
      return directAuthCode;
    }

    if (uri.fragment.isEmpty) {
      return null;
    }

    final fragmentUri = Uri.tryParse(
      uri.fragment.startsWith("/") ? uri.fragment : "/${uri.fragment}",
    );

    final fragmentAuthCode = fragmentUri?.queryParameters["authCode"];
    if (fragmentAuthCode != null && fragmentAuthCode.isNotEmpty) {
      return fragmentAuthCode;
    }

    return null;
  }
}
