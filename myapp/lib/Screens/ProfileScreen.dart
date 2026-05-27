import 'package:flutter/material.dart';

///
/// MODEL
///
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

///
/// REPOSITORY
/// Replace with API / Firebase later
///
class ProfileRepository {
  Future<Map<String, dynamic>> fetchProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      "name": "John Doe",
      "image": "https://i.pravatar.cc/300",
      "currency": "IDR (Rp)",
      "language": "English",
    };
  }

  ///
  /// ACCOUNT MENUS
  ///
  List<ProfileMenu> getAccountMenus() {
    return [
      ProfileMenu(
        title: "Personal Information",
        icon: Icons.person_outline,
        iconColor: Colors.amber,
      ),

      ProfileMenu(
        title: "Login & Security",
        icon: Icons.shield_outlined,
        iconColor: Colors.amber,
      ),
    ];
  }

  ///
  /// PREFERENCE MENUS
  ///
  List<ProfileMenu> getPreferenceMenus({
    required String currency,
    required String language,
  }) {
    return [
      ProfileMenu(
        title: "Notifications",
        icon: Icons.notifications_none,
        iconColor: Colors.amber,
      ),

      ProfileMenu(
        title: "Currency",
        icon: Icons.currency_exchange,
        iconColor: Colors.amber,
        trailingText: currency,
      ),

      ProfileMenu(
        title: "Language",
        icon: Icons.language,
        iconColor: Colors.amber,
        trailingText: language,
      ),
    ];
  }

  ///
  /// MODE MENUS
  ///
  List<ProfileMenu> getModeMenus() {
    return [
      ProfileMenu(
        title: "Dark Mode",
        icon: Icons.dark_mode_outlined,
        iconColor: Colors.amber,
      ),
    ];
  }
}

///
/// PROFILE SCREEN
///
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository repository = ProfileRepository();

  late Future<Map<String, dynamic>> profileFuture;

  @override
  void initState() {
    super.initState();

    profileFuture = repository.fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: profileFuture,
        builder: (context, snapshot) {
          ///
          /// LOADING
          ///
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          ///
          /// ERROR
          ///
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          ///
          /// DATA
          ///
          final data = snapshot.data ?? {};

          final String name = data["name"] ?? "";

          final String image = data["image"] ?? "";

          final String currency = data["currency"] ?? "";

          final String language = data["language"] ?? "";

          final accountMenus = repository.getAccountMenus();

          final preferenceMenus = repository.getPreferenceMenus(
            currency: currency,
            language: language,
          );

          final modeMenus = repository.getModeMenus();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///
                /// HEADER
                ///
                const Center(
                  child: Text(
                    "Settings",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 30),

                ///
                /// PROFILE IMAGE
                ///
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.amber.shade200,
                        backgroundImage: NetworkImage(image),
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
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {},
                            icon: const Icon(Icons.edit, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                ///
                /// NAME
                ///
                Center(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                ///
                /// ACCOUNT SECTION
                ///
                buildSectionTitle("ACCOUNT"),

                const SizedBox(height: 10),

                ProfileMenuCard(menus: accountMenus),

                const SizedBox(height: 24),

                ///
                /// PREFERENCES
                ///
                buildSectionTitle("PREFERENCES"),

                const SizedBox(height: 10),

                ProfileMenuCard(menus: preferenceMenus),

                const SizedBox(height: 24),

                ///
                /// MODE
                ///
                buildSectionTitle("MODE"),

                const SizedBox(height: 10),

                ProfileMenuCard(menus: modeMenus),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  ///
  /// SECTION TITLE
  ///
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

///
/// PROFILE MENU CARD
///
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

///
/// MENU TILE
///
class ProfileMenuTile extends StatelessWidget {
  final ProfileMenu menu;

  const ProfileMenuTile({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

      ///
      /// ICON
      ///
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: menu.iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(menu.icon, color: menu.iconColor),
      ),

      ///
      /// TITLE
      ///
      title: Text(
        menu.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),

      ///
      /// TRAILING
      ///
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
