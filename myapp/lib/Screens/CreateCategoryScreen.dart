import 'package:flutter/material.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final TextEditingController categoryController = TextEditingController(
    text: "Groceries",
  );

  int selectedColorIndex = 0;
  int selectedIconIndex = 0;

  final List<Color> colors = [
    Colors.amber,
    Colors.blue,
    Colors.red,
    const Color(0xFFEAB308),
    Colors.purple,
    Colors.pink,
    Colors.teal,
  ];

  final List<IconData> icons = [
    Icons.shopping_cart_outlined,
    Icons.restaurant_outlined,
    Icons.directions_car_outlined,
    Icons.home_outlined,
    Icons.flight_outlined,
    Icons.checkroom_outlined,
    Icons.medical_services_outlined,
    Icons.sports_esports_outlined,
    Icons.fitness_center_outlined,
    Icons.pets_outlined,
    Icons.school_outlined,
    Icons.shopping_bag_outlined,
    Icons.savings_outlined,
    Icons.attach_money_outlined,
    Icons.wallet_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Add New Category",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Category Name
              const Text(
                "Category Name",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  hintText: "Enter category name",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Theme Color
              const Text(
                "Theme Color",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  ...List.generate(colors.length, (index) {
                    final isSelected = selectedColorIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColorIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors[index],
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.amber, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }),

                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Icon Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Icon",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "See All",
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Icons Grid
              Expanded(
                child: GridView.builder(
                  itemCount: icons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final isSelected = selectedIconIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIconIndex = index;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected
                              ? Border.all(color: Colors.amber, width: 2)
                              : null,
                        ),
                        child: Icon(
                          icons[index],
                          color: isSelected
                              ? Colors.amber
                              : const Color(0xFF64748B),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
