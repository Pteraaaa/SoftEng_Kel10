import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/Models/UsersModel.dart';
import 'package:myapp/Screens/LoginSecurityScreen.dart';
import 'package:myapp/Screens/PersonalInformationScreen.dart';
import 'package:myapp/Services/AuthService.dart';

class ProfileMenu {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String? trailingText;
  final VoidCallback? onTap;

  const ProfileMenu({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.trailingText,
    this.onTap,
  });
}

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

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
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
    final accountMenus = [
      ProfileMenu(
        title: "Personal Information",
        icon: Icons.person_outline,
        iconColor: Colors.amber,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PersonalInformationScreen(
                user: currentUser,
                onUserChanged: updateCurrentUser,
              ),
            ),
          );
        },
      ),
      ProfileMenu(
        title: "Login & Security",
        icon: Icons.shield_outlined,
        iconColor: Colors.amber,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  LoginSecurityScreen(
                    user: currentUser,
                    onUserChanged: updateCurrentUser,
                  ),
            ),
          );
        },
      ),
    ];

    final preferenceMenus = [
      const ProfileMenu(
        title: "Notifications",
        icon: Icons.notifications_none,
        iconColor: Colors.amber,
      ),
      const ProfileMenu(
        title: "Currency",
        icon: Icons.currency_exchange,
        iconColor: Colors.amber,
        trailingText: "IDR (Rp)",
      ),
      const ProfileMenu(
        title: "Language",
        icon: Icons.language,
        iconColor: Colors.amber,
        trailingText: "English",
      ),
    ];

    final modeMenus = [
      const ProfileMenu(
        title: "Dark Mode",
        icon: Icons.dark_mode_outlined,
        iconColor: Colors.amber,
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Settings",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.amber.shade200,
                    backgroundImage: _profileImageProvider(
                      currentUser.profileImage,
                    ),
                    child: currentUser.profileImage.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 54,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: isChangingAvatar ? null : changeAvatar,
                        icon: isChangingAvatar
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.edit, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (avatarError != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  avatarError!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Center(
              child: Text(
                currentUser.username.isEmpty ? "User" : currentUser.username,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                currentUser.email,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 30),
            buildSectionTitle("ACCOUNT"),
            const SizedBox(height: 10),
            ProfileMenuCard(menus: accountMenus),
            const SizedBox(height: 24),
            buildSectionTitle("PREFERENCES"),
            const SizedBox(height: 10),
            ProfileMenuCard(menus: preferenceMenus),
            const SizedBox(height: 24),
            buildSectionTitle("MODE"),
            const SizedBox(height: 10),
            ProfileMenuCard(menus: modeMenus),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void updateCurrentUser(UsersModel user) {
    setState(() {
      currentUser = user;
    });
    widget.onUserChanged(user);
  }

  Future<void> changeAvatar() async {
    final avatar = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (avatar == null) {
      return;
    }

    setState(() {
      isChangingAvatar = true;
      avatarError = null;
    });

    try {
      final avatarUrl = await AuthService.changeAvatarUrl(avatar);
      if (!mounted) return;

      updateCurrentUser(currentUser.copyWith(profileImage: avatarUrl));
    } catch (error) {
      if (!mounted) return;
      if (error is TokenExpiredException) {
        await showTokenExpiredAlert();
        return;
      }

      setState(() {
        avatarError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isChangingAvatar = false;
        });
      }
    }
  }

  Future<void> showTokenExpiredAlert() async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Error"),
          content: const Text(
            "something wrong, maybe session is expired please login again",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  ImageProvider? _profileImageProvider(String image) {
    if (image.isEmpty) {
      return null;
    }

    if (image.startsWith("http")) {
      return NetworkImage(image);
    }

    return NetworkImage("${AuthService.baseUrl}$image");
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
      ),
    );
  }
}

class ProfileMenuCard extends StatelessWidget {
  final List<ProfileMenu> menus;

  const ProfileMenuCard({super.key, required this.menus});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: List.generate(menus.length, (index) {
          final menu = menus[index];

          return Column(
            children: [
              ProfileMenuTile(menu: menu),
              if (index != menus.length - 1)
                Divider(height: 1, color: Colors.grey.shade200),
            ],
          );
        }),
      ),
    );
  }
}

class ProfileMenuTile extends StatelessWidget {
  final ProfileMenu menu;

  const ProfileMenuTile({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: menu.iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(menu.icon, color: menu.iconColor),
      ),
      title: Text(
        menu.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (menu.trailingText != null)
            Text(
              menu.trailingText!,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
      onTap: menu.onTap,
    );
  }
}
