import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
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
    return const AppRoot();
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final navigatorKey = GlobalKey<NavigatorState>();
  final handledAuthCodes = <String>{};
  late final AppLinks appLinks;
  StreamSubscription<Uri>? linkSubscription;

  @override
  void initState() {
    super.initState();
    appLinks = AppLinks();
    initDeepLinks();
  }

  @override
  void dispose() {
    linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> initDeepLinks() async {
    if (kIsWeb) {
      return;
    }

    try {
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        handleDeepLink(initialLink);
      }
    } catch (_) {
      // The normal auth gate will continue if no initial deep link is available.
    }

    linkSubscription = appLinks.uriLinkStream.listen(
      handleDeepLink,
      onError: (_) {},
    );
  }

  void handleDeepLink(Uri uri) {
    final authCode = AuthCallbackUri.extractAuthCode(uri);
    if (authCode == null || !handledAuthCodes.add(authCode)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        return;
      }

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AuthCallbackScreen(authCode: authCode),
        ),
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authCode = kIsWeb ? AuthCallbackUri.extractAuthCode(Uri.base) : null;

    return MaterialApp(
      navigatorKey: navigatorKey,
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
