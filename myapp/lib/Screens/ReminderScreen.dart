import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Models/ReminderModel.dart';
import 'package:myapp/Services/AuthService.dart';
import 'package:myapp/Services/ReminderSchedulerService.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  late Future<List<ReminderModel>> remindersFuture;

  @override
  void initState() {
    super.initState();
    remindersFuture = AuthService.getReminders();
  }

  Future<void> _reload() async {
    setState(() {
      remindersFuture = AuthService.getReminders();
    });
    await remindersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          "Reminder",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<ReminderModel>>(
        future: remindersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(onRetry: _reload);
          }

          final reminders = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _Header(reminderCount: reminders.length),
                const SizedBox(height: 18),
                if (reminders.isEmpty)
                  const _EmptyState()
                else
                  ...reminders.map(
                    (reminder) =>
                        _ReminderCard(reminder: reminder, onChanged: _reload),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int reminderCount;

  const _Header({required this.reminderCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.alarm_rounded, color: Colors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Scheduled reminders",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$reminderCount reminders configured",
                  style: const TextStyle(color: Color(0xFFCBD5E1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatefulWidget {
  final ReminderModel reminder;
  final Future<void> Function() onChanged;

  const _ReminderCard({required this.reminder, required this.onChanged});

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  bool isBusy = false;

  @override
  Widget build(BuildContext context) {
    final reminder = widget.reminder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: reminder.isActive
              ? const Color(0xFFFFC107).withOpacity(0.5)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: reminder.isActive
                      ? const Color(0xFFFFF3C4)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  reminder.isActive
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  color: reminder.isActive
                      ? const Color(0xFFB45309)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reminder.note.isEmpty ? "No note" : reminder.note,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: reminder.isActive,
                activeColor: const Color(0xFFFFC107),
                onChanged: isBusy ? null : (_) => _toggle(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _InfoPill(
                icon: Icons.schedule_rounded,
                label: _formatTime(reminder.timeScheduled),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoPill(
                  icon: Icons.calendar_month_outlined,
                  label: _shortDays(reminder.daysActive),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : _delete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text("Delete"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : _edit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text("Edit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggle() async {
    await _runAction(() => AuthService.toggleReminder(widget.reminder.id));
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Delete Reminder"),
        content: const Text("This reminder will be removed permanently."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _runAction(() => AuthService.deleteReminder(widget.reminder.id));
    }
  }

  Future<void> _edit() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditReminderSheet(reminder: widget.reminder),
    );

    if (changed == true) {
      await widget.onChanged();
      await ReminderSchedulerService.instance.resyncSafely();
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => isBusy = true);
    try {
      await action();
      await widget.onChanged();
      await ReminderSchedulerService.instance.resyncSafely();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  String _formatTime(String value) {
    try {
      return DateFormat("HH:mm").format(DateFormat("HH:mm:ss").parse(value));
    } catch (_) {
      return value;
    }
  }

  String _shortDays(String value) {
    final days = value
        .split(",")
        .map((day) => day.trim())
        .where((day) => day.isNotEmpty)
        .map((day) => day.length <= 3 ? day : day.substring(0, 3))
        .join(", ");
    return days.isEmpty ? "No active days" : days;
  }
}

class _EditReminderSheet extends StatefulWidget {
  final ReminderModel reminder;

  const _EditReminderSheet({required this.reminder});

  @override
  State<_EditReminderSheet> createState() => _EditReminderSheetState();
}

class _EditReminderSheetState extends State<_EditReminderSheet> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController noteController;
  late TimeOfDay selectedTime;
  late Set<String> selectedDays;
  bool isSubmitting = false;
  String? errorMessage;

  final days = const [
    ("Monday", "Mon"),
    ("Tuesday", "Tue"),
    ("Wednesday", "Wed"),
    ("Thursday", "Thu"),
    ("Friday", "Fri"),
    ("Saturday", "Sat"),
    ("Sunday", "Sun"),
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.reminder.title);
    noteController = TextEditingController(text: widget.reminder.note);
    selectedTime = _parseTime(widget.reminder.timeScheduled);
    selectedDays = widget.reminder.daysActive
        .split(",")
        .map((day) => day.trim())
        .where((day) => day.isNotEmpty)
        .toSet();
  }

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Edit Reminder",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  decoration: _decoration("Title", Icons.title),
                  validator: (value) =>
                      (value ?? "").trim().isEmpty ? "Title is required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: _decoration("Note", Icons.notes_outlined),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedTime.format(context),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Active Days",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: days.map((day) {
                    final selected = selectedDays.contains(day.$1);
                    return ChoiceChip(
                      label: Text(day.$2),
                      selected: selected,
                      selectedColor: const Color(0xFFFFC107),
                      onSelected: (_) {
                        setState(() {
                          if (selected) {
                            selectedDays.remove(day.$1);
                          } else {
                            selectedDays.add(day.$1);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
                const SizedBox(height: 22),
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
                        : const Icon(Icons.check_rounded),
                    label: Text(isSubmitting ? "Saving..." : "Save Changes"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (selectedDays.isEmpty) {
      setState(() => errorMessage = "Please choose at least one active day");
      return;
    }

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      await AuthService.editReminder(
        id: widget.reminder.id,
        title: titleController.text.trim(),
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
        timeScheduled:
            "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00",
        daysActive: selectedDays.join(","),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(":");
    if (parts.length >= 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? TimeOfDay.now().hour,
        minute: int.tryParse(parts[1]) ?? TimeOfDay.now().minute,
      );
    }
    return TimeOfDay.now();
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.alarm_off_rounded, size: 42, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            "No reminders yet",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            "Create reminders from the add button on the main navigation.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 42),
          const SizedBox(height: 10),
          const Text("Failed to load reminders"),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text("Try Again")),
        ],
      ),
    );
  }
}
