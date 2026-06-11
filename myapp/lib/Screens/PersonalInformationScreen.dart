import 'package:flutter/material.dart';
import 'package:myapp/Models/UsersModel.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:myapp/Widgets/HoverTapScale.dart';

class PersonalInformationScreen extends StatefulWidget {
  final UsersModel user;

  const PersonalInformationScreen({required this.user, super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  late UsersModel currentUser;
  late final TextEditingController nameController;
  String? pageError;
  String? nameError;
  bool isUpdating = false;
  bool isEditingName = false;
  bool isSavingName = false;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    nameController = TextEditingController(text: currentUser.username);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, currentUser);
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context, currentUser),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "Personal Information",
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
                const SizedBox(height: 24),
                if (pageError != null) ...[
                  Text(pageError!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                InfoPanel(
                  children: [
                    buildNameTile(),
                    EditableInfoTile(
                      icon: Icons.wc_outlined,
                      label: "Gender",
                      value:
                          currentUser.gender == null ||
                              currentUser.gender!.isEmpty
                          ? "-"
                          : currentUser.gender!,
                      isUpdating: isUpdating,
                      onTap: openChangeGenderDialog,
                    ),
                    EditableInfoTile(
                      icon: Icons.cake_outlined,
                      label: "DOB",
                      value: currentUser.dob == null
                          ? "-"
                          : formatDate(currentUser.dob!),
                      isUpdating: isUpdating,
                      onTap: openChangeDobDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildNameTile() {
    if (!isEditingName) {
      return EditableInfoTile(
        icon: Icons.person_outline,
        label: "Name",
        value: currentUser.username.isEmpty ? "-" : currentUser.username,
        isUpdating: isUpdating || isSavingName,
        onTap: () {
          setState(() {
            nameController.text = currentUser.username;
            nameError = null;
            isEditingName = true;
          });
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_outline, color: Colors.amber),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Name",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            enabled: !isSavingName,
            decoration: const InputDecoration(
              labelText: "Name",
              border: OutlineInputBorder(),
            ),
          ),
          if (nameError != null) ...[
            const SizedBox(height: 8),
            Text(nameError!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: isSavingName
                    ? null
                    : () {
                        setState(() {
                          nameController.text = currentUser.username;
                          nameError = null;
                          isEditingName = false;
                        });
                      },
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: isSavingName ? null : saveInlineName,
                child: Text(isSavingName ? "Saving..." : "Save"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> saveInlineName() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        nameError = "Name is required";
      });
      return;
    }

    setState(() {
      isSavingName = true;
      nameError = null;
      pageError = null;
    });

    try {
      final updatedName = await AuthService.changeName(name);
      if (!mounted) return;

      setState(() {
        currentUser = currentUser.copyWith(username: updatedName);
        nameController.text = updatedName;
        isEditingName = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (error is TokenExpiredException) {
        await showTokenExpiredAlert();
      } else {
        setState(() {
          nameError = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isSavingName = false;
        });
      }
    }
  }

  Future<void> openChangeGenderDialog() async {
    String selectedGender =
        currentUser.gender == null || currentUser.gender!.isEmpty
        ? "Male"
        : currentUser.gender!;
    final genderOptions = ["Male", "Female", "Others"];
    if (!genderOptions.contains(selectedGender)) {
      genderOptions.add(selectedGender);
    }
    String? error;
    bool isSaving = false;

    final updatedGender = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Change Gender"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(labelText: "Gender"),
                    items: genderOptions
                        .map(
                          (gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedGender = value;
                      });
                    },
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() {
                            isSaving = true;
                            error = null;
                          });

                          final updatedGender = await changeGender(
                            selectedGender,
                            onError: (message) {
                              setDialogState(() {
                                error = message;
                              });
                            },
                          );

                          if (updatedGender != null && dialogContext.mounted) {
                            Navigator.pop(dialogContext, updatedGender);
                            return;
                          }

                          if (dialogContext.mounted) {
                            setDialogState(() {
                              isSaving = false;
                            });
                          }
                        },
                  child: Text(isSaving ? "Saving..." : "Save"),
                ),
              ],
            );
          },
        );
      },
    );

    if (updatedGender != null && mounted) {
      updateCurrentUser(currentUser.copyWith(gender: updatedGender));
    }
  }

  Future<void> openChangeDobDialog() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentUser.dob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked == null) {
      return;
    }

    await changeDob(formatDate(picked));
  }

  Future<String?> changeName(
    String name, {
    required ValueChanged<String> onError,
  }) async {
    try {
      final updatedName = await AuthService.changeName(name);
      if (!mounted) return null;

      return updatedName;
    } catch (error) {
      if (!mounted) return null;
      if (error is TokenExpiredException) {
        await showTokenExpiredAlert();
      } else {
        onError(error.toString());
      }
      return null;
    }
  }

  Future<String?> changeGender(
    String gender, {
    required ValueChanged<String> onError,
  }) async {
    try {
      final updatedGender = await AuthService.changeGender(gender);
      if (!mounted) return null;

      return updatedGender;
    } catch (error) {
      if (!mounted) return null;
      if (error is TokenExpiredException) {
        await showTokenExpiredAlert();
      } else {
        onError(error.toString());
      }
      return null;
    }
  }

  Future<void> changeDob(String dob) async {
    setState(() {
      isUpdating = true;
      pageError = null;
    });

    try {
      final updatedDob = await AuthService.changeDob(dob);
      if (!mounted) return;

      updateCurrentUser(currentUser.copyWith(dob: updatedDob));
    } catch (error) {
      if (!mounted) return;
      if (error is TokenExpiredException) {
        await showTokenExpiredAlert();
      } else {
        setState(() {
          pageError = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  void updateCurrentUser(UsersModel user) {
    setState(() {
      currentUser = user;
    });
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

  String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, "0");
    final month = date.month.toString().padLeft(2, "0");
    final day = date.day.toString().padLeft(2, "0");
    return "$year-$month-$day";
  }
}

class InfoPanel extends StatelessWidget {
  final List<Widget> children;

  const InfoPanel({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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

class EditableInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isUpdating;
  final VoidCallback onTap;

  const EditableInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isUpdating,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HoverTapScale(
      onTap: isUpdating ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.amber),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value, style: TextStyle(color: Colors.grey.shade600)),
        ),
        trailing: TextButton(
          onPressed: isUpdating ? null : onTap,
          child: const Text("Change"),
        ),
      ),
    );
  }
}
