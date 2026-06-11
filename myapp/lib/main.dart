import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myapp/Screens/AuthCallbackScreen.dart';
import 'package:myapp/Screens/AuthScreen.dart';
import 'package:myapp/Screens/TemplateScreen.dart';
import 'package:myapp/Services/AppCurrencyService.dart';
import 'package:myapp/Services/AppThemeService.dart';
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

    return ValueListenableBuilder<bool>(
      valueListenable: AppThemeService.isDarkMode,
      builder: (context, isDarkMode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: "Pocket Log",
          debugShowCheckedModeBanner: false,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: authCode == null
              ? const AuthGate()
              : AuthCallbackScreen(authCode: authCode),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.amber,
      brightness: brightness,
    );
    final background = isDark ? const Color(0xFF0F172A) : appBackgroundColor;

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final hoverOverlay = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.hovered)) {
        return Colors.amber.withValues(alpha: isDark ? 0.16 : 0.18);
      }
      if (states.contains(WidgetState.pressed)) {
        return Colors.amber.withValues(alpha: 0.24);
      }
      return null;
    });

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: buttonShape,
          animationDuration: const Duration(milliseconds: 150),
        ).copyWith(overlayColor: hoverOverlay),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: buttonShape,
          animationDuration: const Duration(milliseconds: 150),
        ).copyWith(overlayColor: hoverOverlay),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          animationDuration: const Duration(milliseconds: 150),
        ).copyWith(overlayColor: hoverOverlay),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: hoverOverlay,
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
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
      try {
        final settings = await AuthService.getUserSettings();
        final settingsData = settings["data"];
        final isDark =
            settingsData is Map<String, dynamic> &&
            settingsData["appearance"]?.toString().toLowerCase() == "dark";
        AppThemeService.setDarkMode(isDark);
        if (settingsData is Map<String, dynamic>) {
          AppCurrencyService.setCurrency(
            settingsData["currency"]?.toString() ?? "IDR",
          );
        }
      } catch (_) {
        // Settings are not part of the authentication decision.
      }
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
