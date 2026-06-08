import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myapp/Models/UsersModel.dart';
import 'package:myapp/Screens/AuthScreen.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:myapp/Services/GoogleAuthService.dart';
import 'package:myapp/Services/TokenStorage.dart';
import 'package:myapp/Widgets/GoogleWebSignInButton.dart';

class LoginSecurityScreen extends StatefulWidget {
  final UsersModel user;
  final ValueChanged<UsersModel> onUserChanged;

  const LoginSecurityScreen({
    required this.user,
    required this.onUserChanged,
    super.key,
  });

  @override
  State<LoginSecurityScreen> createState() => _LoginSecurityScreenState();
}

class _LoginSecurityScreenState extends State<LoginSecurityScreen> {
  late UsersModel currentUser;
  bool isLoading = true;
  bool isGoogleActionLoading = false;
  bool isLogoutLoading = false;
  String? authType;
  bool googleBound = false;
  String? pageError;
  String? googleError;
  String? logoutError;
  StreamSubscription? googleAccountSubscription;

  bool get isProviderAuth => authType == "ProviderAuth";
  bool get isProviderOnlyAccount => currentUser.password == null;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    listenForGoogleBind();
    if (kIsWeb) {
      GoogleAuthService.prepareWebSignIn();
    }
    loadSecurityState();
  }

  @override
  void dispose() {
    googleAccountSubscription?.cancel();
    super.dispose();
  }

  void listenForGoogleBind() {
    googleAccountSubscription = GoogleAuthService.onCurrentUserChanged.listen((
      account,
    ) async {
      if (!kIsWeb ||
          account == null ||
          googleBound ||
          isGoogleActionLoading) {
        return;
      }

      String googleIdToken;
      try {
        googleIdToken = await GoogleAuthService.getGoogleIdTokenFromAccount(
          account,
        );
      } catch (_) {
        return;
      }

      await bindCurrentGoogleAccount(googleIdToken);
    });
  }

  Future<void> loadSecurityState() async {
    setState(() {
      isLoading = true;
      pageError = null;
    });

    try {
      final auth = await AuthService.checkAuth();
      final providerStatus = await AuthService.checkProviderStatus();

      if (!mounted) return;

      setState(() {
        authType = auth;
        googleBound = providerStatus.googleBound;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (error is TokenExpiredException) {
        await handleSessionExpired();
        return;
      }

      setState(() {
        pageError = error.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              "Login & Security",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (pageError != null)
                      ErrorText(message: pageError!)
                    else ...[
                      SectionTitle("ACCOUNT ACCESS"),
                      const SizedBox(height: 10),
                      SecurityPanel(
                        children: [
                          SecurityActionTile(
                            icon: Icons.email_outlined,
                            title: "Email",
                            subtitle: currentUser.email,
                            actionLabel: "Change",
                            onTap: openChangeEmailDialog,
                          ),
                          SecurityActionTile(
                            icon: Icons.lock_outline,
                            title: "Password",
                            subtitle: isProviderAuth
                                ? "Disabled for provider login"
                                : maskedPassword,
                            actionLabel: "Change",
                            disabled: isProviderAuth,
                            onTap: openChangePasswordDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SectionTitle("CONNECTED ACCOUNT"),
                      const SizedBox(height: 10),
                      SecurityPanel(
                        children: [
                          SecurityActionTile(
                            icon: Icons.g_mobiledata,
                            title: "Google Account",
                            subtitle: googleBound
                                ? "Google account is connected"
                                : "Google account is not connected",
                            actionLabel: googleBound ? "Unbind" : "Bind",
                            isLoading: isGoogleActionLoading,
                            trailing: !googleBound && kIsWeb
                                ? const GoogleWebSignInButton()
                                : null,
                            onTap: toggleGoogleBind,
                          ),
                          if (googleError != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: ErrorText(message: googleError!),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SectionTitle("SESSION"),
                      const SizedBox(height: 10),
                      SecurityPanel(
                        children: [
                          SecurityActionTile(
                            icon: Icons.logout,
                            title: "Logout",
                            subtitle: "End this session on your device",
                            actionLabel: isLogoutLoading ? "..." : "Logout",
                            onTap: logout,
                          ),
                          if (logoutError != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: ErrorText(message: logoutError!),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SectionTitle("DANGER ZONE"),
                      const SizedBox(height: 10),
                      SecurityPanel(
                        children: [
                          SecurityActionTile(
                            icon: Icons.delete_outline,
                            title: "Delete Account",
                            subtitle: isProviderAuth
                                ? "Disabled for provider login"
                                : "Permanently remove your account",
                            actionLabel: "Delete",
                            danger: true,
                            disabled: isProviderAuth,
                            onTap: openDeleteAccountDialog,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  String get maskedPassword => "************";

  Future<void> openChangeEmailDialog() async {
    final newEmailController = TextEditingController();
    final otpController = TextEditingController();
    String? challengeToken;
    String? otpRequestError;
    String? confirmError;
    String? successMessage;
    bool isSendingOtp = false;
    bool isConfirming = false;
    bool dialogClosed = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> sendOtp() async {
              final newEmail = newEmailController.text.trim();
              if (newEmail.isEmpty || !newEmail.contains("@")) {
                setDialogState(() {
                  otpRequestError = "New email is required";
                });
                return;
              }

              setDialogState(() {
                isSendingOtp = true;
                otpRequestError = null;
                confirmError = null;
                successMessage = null;
              });

              try {
                final token = await AuthService.requestChangeEmailOtp(newEmail);
                if (!mounted) return;
                setDialogState(() {
                  challengeToken = token;
                  successMessage = "OTP sent to your current email";
                });
              } catch (error) {
                if (!mounted) return;
                if (error is TokenExpiredException) {
                  if (!dialogContext.mounted) return;
                  dialogClosed = true;
                  Navigator.pop(dialogContext);
                  await handleSessionExpired();
                  return;
                }
                setDialogState(() {
                  otpRequestError = error.toString();
                });
              } finally {
                if (mounted && !dialogClosed) {
                  setDialogState(() {
                    isSendingOtp = false;
                  });
                }
              }
            }

            Future<void> confirm() async {
              if (challengeToken == null || challengeToken!.isEmpty) {
                setDialogState(() {
                  confirmError = "Please send OTP first";
                });
                return;
              }

              if (otpController.text.trim().isEmpty) {
                setDialogState(() {
                  confirmError = "OTP code is required";
                });
                return;
              }

              setDialogState(() {
                isConfirming = true;
                confirmError = null;
              });

              try {
                final updatedEmail = await AuthService.confirmChangeEmail(
                  otpCode: otpController.text.trim(),
                  challengeToken: challengeToken!,
                );
                if (!mounted) return;

                final updatedUser = currentUser.copyWith(
                  email: updatedEmail.isEmpty
                      ? newEmailController.text.trim()
                      : updatedEmail,
                );

                setState(() {
                  currentUser = updatedUser;
                });
                widget.onUserChanged(updatedUser);
                if (!dialogContext.mounted) return;
                dialogClosed = true;
                Navigator.pop(dialogContext);
              } catch (error) {
                if (!mounted) return;
                if (error is TokenExpiredException) {
                  if (!dialogContext.mounted) return;
                  dialogClosed = true;
                  Navigator.pop(dialogContext);
                  await handleSessionExpired();
                  return;
                }
                setDialogState(() {
                  confirmError = error.toString();
                });
              } finally {
                if (mounted && !dialogClosed) {
                  setDialogState(() {
                    isConfirming = false;
                  });
                }
              }
            }

            return SecurityDialog(
              title: "Change Email",
              children: [
                DialogTextField(
                  controller: newEmailController,
                  label: "New Email",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                InfoLine(label: "Current email", value: currentUser.email),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isSendingOtp ? null : sendOtp,
                    child: Text(isSendingOtp ? "Sending..." : "Send OTP"),
                  ),
                ),
                if (otpRequestError != null)
                  ErrorText(message: otpRequestError!),
                if (successMessage != null)
                  SuccessText(message: successMessage!),
                const SizedBox(height: 12),
                DialogTextField(
                  controller: otpController,
                  label: "OTP Code",
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                ),
                if (confirmError != null) ErrorText(message: confirmError!),
                const SizedBox(height: 18),
                DialogConfirmButton(
                  label: isConfirming ? "Confirming..." : "Confirm",
                  onPressed: isConfirming ? null : confirm,
                ),
              ],
            );
          },
        );
      },
    );

    newEmailController.dispose();
    otpController.dispose();
  }

  Future<void> openChangePasswordDialog() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final otpController = TextEditingController();
    String? challengeToken;
    String? otpRequestError;
    String? confirmError;
    String? successMessage;
    bool isSendingOtp = false;
    bool isConfirming = false;
    bool dialogClosed = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> sendOtp() async {
              setDialogState(() {
                isSendingOtp = true;
                otpRequestError = null;
                confirmError = null;
                successMessage = null;
              });

              try {
                final token = await AuthService.requestChangePasswordOtp(
                  oldPasswordController.text,
                );
                if (!mounted) return;
                setDialogState(() {
                  challengeToken = token;
                  successMessage = "OTP sent to your email";
                });
              } catch (error) {
                if (!mounted) return;
                if (error is TokenExpiredException) {
                  if (!dialogContext.mounted) return;
                  dialogClosed = true;
                  Navigator.pop(dialogContext);
                  await handleSessionExpired();
                  return;
                }
                setDialogState(() {
                  otpRequestError = error.toString();
                });
              } finally {
                if (mounted && !dialogClosed) {
                  setDialogState(() {
                    isSendingOtp = false;
                  });
                }
              }
            }

            Future<void> confirm() async {
              if (challengeToken == null || challengeToken!.isEmpty) {
                setDialogState(() {
                  confirmError = "Please send OTP first";
                });
                return;
              }

              if (otpController.text.trim().isEmpty) {
                setDialogState(() {
                  confirmError = "OTP code is required";
                });
                return;
              }

              setDialogState(() {
                isConfirming = true;
                confirmError = null;
              });

              try {
                await AuthService.confirmChangePassword(
                  otpCode: otpController.text.trim(),
                  newPassword: newPasswordController.text,
                  challengeToken: challengeToken!,
                );
                final refreshedUser = await AuthService.getMeWithRefresh();
                if (!mounted) return;

                setState(() {
                  currentUser = refreshedUser;
                });
                widget.onUserChanged(refreshedUser);
                if (!dialogContext.mounted) return;
                dialogClosed = true;
                Navigator.pop(dialogContext);
              } catch (error) {
                if (!mounted) return;
                if (error is TokenExpiredException) {
                  if (!dialogContext.mounted) return;
                  dialogClosed = true;
                  Navigator.pop(dialogContext);
                  await handleSessionExpired();
                  return;
                }
                setDialogState(() {
                  confirmError = error.toString();
                });
              } finally {
                if (mounted && !dialogClosed) {
                  setDialogState(() {
                    isConfirming = false;
                  });
                }
              }
            }

            return SecurityDialog(
              title: "Change Password",
              children: [
                DialogTextField(
                  controller: oldPasswordController,
                  label: "Old Password",
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DialogTextField(
                  controller: newPasswordController,
                  label: "New Password",
                  icon: Icons.lock_reset,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                InfoLine(label: "Email", value: currentUser.email),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isSendingOtp ? null : sendOtp,
                    child: Text(isSendingOtp ? "Sending..." : "Send OTP"),
                  ),
                ),
                if (otpRequestError != null)
                  ErrorText(message: otpRequestError!),
                if (successMessage != null)
                  SuccessText(message: successMessage!),
                const SizedBox(height: 12),
                DialogTextField(
                  controller: otpController,
                  label: "OTP Code",
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                ),
                if (confirmError != null) ErrorText(message: confirmError!),
                const SizedBox(height: 18),
                DialogConfirmButton(
                  label: isConfirming ? "Confirming..." : "Confirm",
                  onPressed: isConfirming ? null : confirm,
                ),
              ],
            );
          },
        );
      },
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    otpController.dispose();
  }

  Future<void> openDeleteAccountDialog() async {
    final passwordController = TextEditingController();
    final otpController = TextEditingController();
    String? challengeToken;
    String? otpRequestError;
    String? confirmError;
    String? successMessage;
    bool isSendingOtp = false;
    bool isConfirming = false;
    bool dialogClosed = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> sendOtp() async {
              setDialogState(() {
                isSendingOtp = true;
                otpRequestError = null;
                confirmError = null;
                successMessage = null;
              });

              try {
                final token = await AuthService.requestDeleteAccountOtp(
                  passwordController.text,
                );
                if (!mounted) return;
                setDialogState(() {
                  challengeToken = token;
                  successMessage = "OTP sent to your email";
                });
              } catch (error) {
                if (!mounted) return;
                if (error is TokenExpiredException) {
                  if (!dialogContext.mounted) return;
                  dialogClosed = true;
                  Navigator.pop(dialogContext);
                  await handleSessionExpired();
                  return;
                }
                setDialogState(() {
                  otpRequestError = error.toString();
                });
              } finally {
                if (mounted && !dialogClosed) {
                  setDialogState(() {
                    isSendingOtp = false;
                  });
                }
              }
            }

            Future<void> confirm() async {
              if (challengeToken == null || challengeToken!.isEmpty) {
                setDialogState(() {
                  confirmError = "Please send OTP first";
                });
                return;
              }

              if (otpController.text.trim().isEmpty) {
                setDialogState(() {
                  confirmError = "OTP code is required";
                });
                return;
              }

              setDialogState(() {
                isConfirming = true;
                confirmError = null;
              });

              try {
                await AuthService.confirmDeleteAccount(
                  otpCode: otpController.text.trim(),
                  challengeToken: challengeToken!,
                );
                if (!mounted) return;
                if (!dialogContext.mounted) return;
                dialogClosed = true;
                Navigator.pop(dialogContext);
                goToLogin();
              } catch (error) {
                if (!mounted) return;
                if (error is TokenExpiredException) {
                  if (!dialogContext.mounted) return;
                  dialogClosed = true;
                  Navigator.pop(dialogContext);
                  await handleSessionExpired();
                  return;
                }
                setDialogState(() {
                  confirmError = error.toString();
                });
              } finally {
                if (mounted && !dialogClosed) {
                  setDialogState(() {
                    isConfirming = false;
                  });
                }
              }
            }

            return SecurityDialog(
              title: "Delete Account",
              danger: true,
              children: [
                DialogTextField(
                  controller: passwordController,
                  label: "Your Password",
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                InfoLine(label: "Email", value: currentUser.email),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isSendingOtp ? null : sendOtp,
                    child: Text(isSendingOtp ? "Sending..." : "Send OTP"),
                  ),
                ),
                if (otpRequestError != null)
                  ErrorText(message: otpRequestError!),
                if (successMessage != null)
                  SuccessText(message: successMessage!),
                const SizedBox(height: 12),
                DialogTextField(
                  controller: otpController,
                  label: "OTP Code",
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                ),
                if (confirmError != null) ErrorText(message: confirmError!),
                const SizedBox(height: 18),
                DialogConfirmButton(
                  label: isConfirming ? "Deleting..." : "Confirm Delete",
                  danger: true,
                  onPressed: isConfirming ? null : confirm,
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    otpController.dispose();
  }

  Future<void> bindCurrentGoogleAccount(String googleIdToken) async {
    setState(() {
      isGoogleActionLoading = true;
      googleError = null;
    });

    try {
      await AuthService.bindGoogle(googleIdToken);

      if (!mounted) return;

      setState(() {
        googleBound = true;
      });
    } catch (error) {
      if (!mounted) return;
      if (error is TokenExpiredException) {
        await handleSessionExpired();
        return;
      }

      setState(() {
        googleError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isGoogleActionLoading = false;
        });
      }
    }
  }

  Future<void> toggleGoogleBind() async {
    setState(() {
      isGoogleActionLoading = true;
      googleError = null;
    });

    try {
      if (googleBound) {
        final shouldGoToLoginAfterUnbind = isProviderOnlyAccount;
        if (isProviderOnlyAccount) {
          setState(() {
            isGoogleActionLoading = false;
          });

          final confirmed = await showProviderOnlyUnbindWarning();
          if (!confirmed) {
            return;
          }

          if (!mounted) return;
          setState(() {
            isGoogleActionLoading = true;
          });
        }

        final result = await AuthService.unbindGoogle();

        if (!mounted) return;

        if (shouldGoToLoginAfterUnbind || result.accountDeleted) {
          await TokenStorage.clear();
          if (!mounted) return;
          goToLogin();
          return;
        }
      } else {
        final googleIdToken = await GoogleAuthService.getGoogleIdToken();
        await AuthService.bindGoogle(googleIdToken);
      }

      if (!mounted) return;

      setState(() {
        googleBound = !googleBound;
      });
    } catch (error) {
      if (!mounted) return;
      if (error is TokenExpiredException) {
        await handleSessionExpired();
        return;
      }

      setState(() {
        googleError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isGoogleActionLoading = false;
        });
      }
    }
  }

  Future<bool> showProviderOnlyUnbindWarning() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Warning"),
          content: const Text(
            "This account only uses Google login. If you unbind Google, this account will be deleted and you will not be able to log in again.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Continue Unbind"),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> logout() async {
    setState(() {
      isLogoutLoading = true;
      logoutError = null;
    });

    try {
      await AuthService.logout();
      if (!mounted) return;
      goToLogin();
    } catch (error) {
      if (!mounted) return;
      if (error is TokenExpiredException) {
        await handleSessionExpired();
        return;
      }

      setState(() {
        logoutError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLogoutLoading = false;
        });
      }
    }
  }

  Future<void> handleSessionExpired() async {
    await TokenStorage.clear();
    if (!mounted) return;

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
    goToLogin();
  }

  void goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
      ),
    );
  }
}

class SecurityPanel extends StatelessWidget {
  final List<Widget> children;

  const SecurityPanel({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          return Column(
            children: [
              children[index],
              if (index != children.length - 1)
                Divider(height: 1, color: Colors.grey.shade200),
            ],
          );
        }),
      ),
    );
  }
}

class SecurityActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  final bool disabled;
  final bool isLoading;

  const SecurityActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.disabled = false,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = danger ? Colors.red : Colors.amber;
    final textColor = disabled ? Colors.grey : Colors.black87;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: disabled ? 0.06 : 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: disabled ? Colors.grey : accentColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            color: disabled ? Colors.grey : Colors.grey.shade600,
          ),
        ),
      ),
      trailing:
          trailing ??
          TextButton(
            onPressed: disabled || isLoading ? null : onTap,
            child: Text(
              actionLabel,
              style: TextStyle(
                color: danger ? Colors.red : Colors.amber.shade800,
              ),
            ),
          ),
    );
  }
}

class SecurityDialog extends StatelessWidget {
  final String title;
  final bool danger;
  final List<Widget> children;

  const SecurityDialog({
    required this.title,
    required this.children,
    this.danger = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: danger ? Colors.red : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const DialogTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class DialogConfirmButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  const DialogConfirmButton({
    required this.label,
    required this.onPressed,
    this.danger = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: danger ? Colors.red : Colors.amber,
          foregroundColor: danger ? Colors.white : Colors.black,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const InfoLine({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ErrorText extends StatelessWidget {
  final String message;

  const ErrorText({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}

class SuccessText extends StatelessWidget {
  final String message;

  const SuccessText({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(message, style: const TextStyle(color: Colors.green)),
    );
  }
}
