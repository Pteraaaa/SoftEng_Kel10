class ReminderModel {
  final String id;
  final String title;
  final String note;
  final String timeScheduled;
  final String daysActive;
  final bool isActive;

  const ReminderModel({
    required this.id,
    required this.title,
    required this.note,
    required this.timeScheduled,
    required this.daysActive,
    required this.isActive,
  });

  factory ReminderModel.fromApi(Map<String, dynamic> data) {
    final activeValue = data["is_active"];

    return ReminderModel(
      id: data["id"]?.toString() ?? "",
      title: data["title"]?.toString() ?? "",
      note: data["note"]?.toString() ?? "",
      timeScheduled: data["time_scheduled"]?.toString() ?? "",
      daysActive: data["days_active"]?.toString() ?? "",
      isActive: activeValue == true || activeValue == 1 || activeValue == "1",
    );
  }
}
