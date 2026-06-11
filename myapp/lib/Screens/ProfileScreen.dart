import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/Models/UsersModel.dart';
import 'package:myapp/Screens/LoginSecurityScreen.dart';
import 'package:myapp/Screens/AuthScreen.dart';
import 'package:myapp/Screens/PersonalInformationScreen.dart';
import 'package:myapp/Screens/ReminderScreen.dart';
import 'package:myapp/Services/AppThemeService.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:myapp/Services/TokenStorage.dart';
import 'package:myapp/Widgets/HoverTapScale.dart';

class ProfileScreen extends StatefulWidget {
  final UsersModel user;
  final ValueChanged<UsersModel> onUserChanged;

  const ProfileScreen({
    required this.user,
    required this.onUserChanged,
    super.key,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UsersModel currentUser;
  bool isChangingAvatar = false;
  String? avatarError;
  bool isDarkMode = false;
  String selectedLanguage = "English";
  bool isSavingSettings = false;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _loadSettings();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      currentUser = widget.user;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDarkMode
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFED8936)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  children: [
                    Text(
                      _t("Profile", "Profil"),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            backgroundImage: _imageProvider(
                              currentUser.profileImage,
                            ),
                            child: currentUser.profileImage.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 52,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: HoverTapScale(
                            onTap: isChangingAvatar ? null : _changeAvatar,
                            borderRadius: BorderRadius.circular(999),
                            hoverScale: 1.1,
                            pressScale: 0.92,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: isChangingAvatar
                                  ? const Padding(
                                      padding: EdgeInsets.all(7),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 18,
                                      color: Color(0xFFF59E0B),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      currentUser.username.isEmpty
                          ? "User"
                          : currentUser.username,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (avatarError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        avatarError!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel("ACCOUNT", color: mutedColor),
                      const SizedBox(height: 10),
                      _MenuCard(
                        color: cardColor,
                        children: [
                          _MenuTile(
                            icon: Icons.person_outline_rounded,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFF59E0B),
                            textColor: textColor,
                            mutedColor: mutedColor,
                            title: _t(
                              "Personal Information",
                              "Informasi Pribadi",
                            ),
                            onTap: _openPersonalInformation,
                          ),
                          _Divider(color: mutedColor.withOpacity(0.14)),
                          _MenuTile(
                            icon: Icons.shield_outlined,
                            iconBg: const Color(0xFFEDE9FE),
                            iconColor: const Color(0xFF7C3AED),
                            textColor: textColor,
                            mutedColor: mutedColor,
                            title: _t("Login & Security", "Login & Keamanan"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginSecurityScreen(
                                    user: currentUser,
                                    onUserChanged: _updateUser,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel("PREFERENCES", color: mutedColor),
                      const SizedBox(height: 10),
                      _MenuCard(
                        color: cardColor,
                        children: [
                          _MenuTile(
                            icon: Icons.alarm_rounded,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFF59E0B),
                            textColor: textColor,
                            mutedColor: mutedColor,
                            title: _t("Reminders", "Pengingat"),
                            subtitle: _t(
                              "${currentUser.username}'s reminders",
                              "Pengingat ${currentUser.username}",
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReminderScreen(),
                                ),
                              );
                            },
                          ),
                          _Divider(color: mutedColor.withOpacity(0.14)),
                          _MenuTile(
                            icon: Icons.language_rounded,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: const Color(0xFF16A34A),
                            textColor: textColor,
                            mutedColor: mutedColor,
                            title: _t("Language", "Bahasa"),
                            trailing: _LanguagePicker(
                              value: selectedLanguage,
                              onChanged: _changeLanguage,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel("APPEARANCE", color: mutedColor),
                      const SizedBox(height: 10),
                      _MenuCard(
                        color: cardColor,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1E293B,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.dark_mode_rounded,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _t("Dark Mode", "Mode Gelap"),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _t(
                                          "Switch app appearance",
                                          "Ubah tampilan aplikasi",
                                        ),
                                        style: TextStyle(
                                          color: mutedColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                isSavingSettings
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Switch(
                                        value: isDarkMode,
                                        activeColor: const Color(0xFFF59E0B),
                                        onChanged: _toggleDarkMode,
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      HoverTapScale(
                        onTap: isSavingSettings ? null : _logout,
                        borderRadius: BorderRadius.circular(16),
                        hoverScale: 1.018,
                        pressScale: 0.97,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _t("Logout", "Keluar"),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPersonalInformation() async {
    final updated = await Navigator.push<UsersModel>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalInformationScreen(user: currentUser),
      ),
    );
    if (!mounted || updated == null) return;
    _updateUser(updated);
  }

  void _updateUser(UsersModel user) {
    setState(() => currentUser = user);
    widget.onUserChanged(user);
  }

  Future<void> _loadSettings() async {
    try {
      final data = await AuthService.getUserSettings();
      final settings = data["data"];
      if (!mounted || settings is! Map<String, dynamic>) return;

      final language = settings["language"]?.toString() ?? "English";
      final appearance = settings["appearance"]?.toString() ?? "Light";
      setState(() {
        selectedLanguage = language.toLowerCase().startsWith("indo")
            ? "Indonesia"
            : "English";
        isDarkMode = appearance.toLowerCase() == "dark";
      });
      AppThemeService.setDarkMode(isDarkMode);
    } catch (_) {
      // Settings are non-blocking for the profile page.
    }
  }

  Future<void> _changeAvatar() async {
    final avatar = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (avatar == null) return;

    setState(() {
      isChangingAvatar = true;
      avatarError = null;
    });

    try {
      final url = await AuthService.changeAvatarUrl(avatar);
      if (!mounted) return;
      _updateUser(currentUser.copyWith(profileImage: url));
    } catch (error) {
      if (!mounted) return;
      if (error is TokenExpiredException) {
        await _showTokenExpired();
        return;
      }
      setState(() => avatarError = error.toString());
    } finally {
      if (mounted) {
        setState(() => isChangingAvatar = false);
      }
    }
  }

  Future<void> _changeLanguage(String language) async {
    final previous = selectedLanguage;
    setState(() {
      selectedLanguage = language;
      isSavingSettings = true;
    });

    try {
      await AuthService.changeSettings(language: language);
    } catch (_) {
      if (!mounted) return;
      setState(() => selectedLanguage = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update language")),
      );
    } finally {
      if (mounted) setState(() => isSavingSettings = false);
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() {
      isDarkMode = value;
      isSavingSettings = true;
    });

    try {
      await AuthService.changeSettings(appearance: value ? "Dark" : "Light");
      AppThemeService.setDarkMode(value);
    } catch (_) {
      if (!mounted) return;
      setState(() => isDarkMode = !value);
      AppThemeService.setDarkMode(!value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update appearance")),
      );
    } finally {
      if (mounted) setState(() => isSavingSettings = false);
    }
  }

  Future<void> _logout() async {
    setState(() => isSavingSettings = true);
    try {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } catch (error) {
      await TokenStorage.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } finally {
      if (mounted) setState(() => isSavingSettings = false);
    }
  }

  Future<void> _showTokenExpired() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Session Expired"),
        content: const Text("Please login again."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  ImageProvider? _imageProvider(String image) {
    if (image.isEmpty) return null;
    if (image.startsWith("http")) return NetworkImage(image);
    return NetworkImage("${AuthService.baseUrl}$image");
  }

  String _t(String english, String indonesia) {
    return selectedLanguage == "Indonesia" ? indonesia : english;
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionLabel(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  final Color color;

  const _MenuCard({required this.children, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color textColor;
  final Color mutedColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MenuTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.textColor,
    required this.mutedColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return HoverTapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      hoverScale: 1.018,
      pressScale: 0.975,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(color: mutedColor, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: mutedColor),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;

  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 72, endIndent: 20, color: color);
  }
}

class _LanguagePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _LanguagePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      isDense: true,
      items: const [
        DropdownMenuItem(
          value: "English",
          child: Text("English", style: TextStyle(fontSize: 13)),
        ),
        DropdownMenuItem(
          value: "Indonesia",
          child: Text("Indonesia", style: TextStyle(fontSize: 13)),
        ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
