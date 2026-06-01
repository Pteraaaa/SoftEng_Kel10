import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleAuthService {
  static const webClientId =
      "743129909126-q6lv4efmcgertkjo8578l4kj5rdkb3rl.apps.googleusercontent.com";

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? webClientId : null,
    serverClientId: kIsWeb ? null : webClientId,
    scopes: ["email", "profile", "openid"],
  );

  static Stream<GoogleSignInAccount?> get onCurrentUserChanged {
    return _googleSignIn.onCurrentUserChanged;
  }

  static Future<void> prepareWebSignIn() async {
    if (kIsWeb) {
      await _googleSignIn.signInSilently();
    }
  }

  static Future<void> redirectToBackend() async {
    final uri = Uri.parse("${AuthService.baseUrl}/Auth/google/");
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: "_self",
    );

    if (!launched) {
      throw Exception("Failed to open Google login");
    }
  }

  static Future<String> getGoogleIdToken() async {
    if (kIsWeb) {
      return getCurrentGoogleIdToken();
    }

    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception("Google login cancelled");
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception("Failed to get Google ID token");
    }

    return idToken;
  }

  static Future<String> getCurrentGoogleIdToken() async {
    final account = _googleSignIn.currentUser;
    if (account == null) {
      throw Exception("Please use the Google button first");
    }

    return getGoogleIdTokenFromAccount(account);
  }

  static Future<String> getGoogleIdTokenFromAccount(
    GoogleSignInAccount account,
  ) async {
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception("Failed to get Google ID token");
    }

    return idToken;
  }
}
