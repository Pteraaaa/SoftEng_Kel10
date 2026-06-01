import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

class GoogleWebSignInButton extends StatelessWidget {
  const GoogleWebSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 44,
      child: google_web.renderButton(
        configuration: google_web.GSIButtonConfiguration(
          type: google_web.GSIButtonType.standard,
          theme: google_web.GSIButtonTheme.outline,
          size: google_web.GSIButtonSize.large,
          text: google_web.GSIButtonText.continueWith,
          shape: google_web.GSIButtonShape.rectangular,
          minimumWidth: 260,
        ),
      ),
    );
  }
}
