import 'package:flutter/material.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:myapp/Widgets/HoverTapScale.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final categoryController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  int selectedColorIndex = 0;
  int selectedIconIndex = 0;
  bool isSubmitting = false;
  String? errorMessage;

  final List<_ColorOption> colors = const [
    _ColorOption("#F59E0B", Color(0xFFF59E0B)),
    _ColorOption("#2563EB", Color(0xFF2563EB)),
    _ColorOption("#DC2626", Color(0xFFDC2626)),
    _ColorOption("#7C3AED", Color(0xFF7C3AED)),
    _ColorOption("#DB2777", Color(0xFFDB2777)),
    _ColorOption("#0F766E", Color(0xFF0F766E)),
    _ColorOption("#16A34A", Color(0xFF16A34A)),
  ];

  final List<_IconOption> icons = const [
    _IconOption("ic_shopping_cart", Icons.shopping_cart_outlined),
    _IconOption("ic_restaurant", Icons.restaurant_outlined),
    _IconOption("ic_directions_car", Icons.directions_car_outlined),
    _IconOption("ic_home", Icons.home_outlined),
    _IconOption("ic_flight", Icons.flight_outlined),
    _IconOption("ic_movie", Icons.movie_outlined),
    _IconOption("ic_medical", Icons.medical_services_outlined),
    _IconOption("ic_school", Icons.school_outlined),
    _IconOption("ic_savings", Icons.savings_outlined),
    _IconOption("ic_work", Icons.work_outline),
    _IconOption("ic_payments", Icons.payments_outlined),
    _IconOption("ic_swap_horiz", Icons.swap_horiz),
  ];

  @override
  void dispose() {
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = colors[selectedColorIndex].color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text("Add New Category"),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : _submit,
            child: Text(isSubmitting ? "Saving..." : "Save"),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: selectedColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      icons[selectedIconIndex].icon,
                      color: selectedColor,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Category Name",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    hintText: "Groceries, Transport, Salary",
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? "").trim().isEmpty) {
                      return "Category name is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  "Theme Color",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(colors.length, (index) {
                    final isSelected = selectedColorIndex == index;
                    return HoverTapScale(
                      onTap: () {
                        setState(() {
                          selectedColorIndex = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colors[index].color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors[index].color.withOpacity(0.20),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 26),
                const Text(
                  "Icon",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: icons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final isSelected = selectedIconIndex == index;
                    return HoverTapScale(
                      onTap: () {
                        setState(() {
                          selectedIconIndex = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedColor.withOpacity(0.14)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? selectedColor
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Icon(
                          icons[index].icon,
                          color: isSelected
                              ? selectedColor
                              : Colors.grey.shade700,
                        ),
                      ),
                    );
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : _submit,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(isSubmitting ? "Saving..." : "Create Category"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      final category = await AuthService.createCategory(
        name: categoryController.text.trim(),
        iconUrl: icons[selectedIconIndex].name,
        colorHex: colors[selectedColorIndex].hex,
      );

      if (!mounted) return;
      Navigator.pop(context, category);
    } on ApiException catch (err) {
      if (!mounted) return;
      setState(() => errorMessage = err.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = "Failed to create category");
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }
}

class _ColorOption {
  final String hex;
  final Color color;

  const _ColorOption(this.hex, this.color);
}

class _IconOption {
  final String name;
  final IconData icon;

  const _IconOption(this.name, this.icon);
}
