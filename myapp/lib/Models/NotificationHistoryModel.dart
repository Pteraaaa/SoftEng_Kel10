class NotificationHistoryModel {
  final String id;
  final String reminderId;
  final String title;
  final String note;
  final DateTime createdAt;
  final String timeScheduled;
  final String daysActive;
  final String day;

  const NotificationHistoryModel({
    required this.id,
    required this.reminderId,
    required this.title,
    required this.note,
    required this.createdAt,
    required this.timeScheduled,
    required this.daysActive,
    required this.day,
  });

  factory NotificationHistoryModel.fromApi(Map<String, dynamic> data) {
    return NotificationHistoryModel(
      id: data["id"]?.toString() ?? "",
      reminderId: data["reminder_id"]?.toString() ?? "",
      title: data["title"]?.toString() ?? "",
      note: data["note"]?.toString() ?? "",
      createdAt:
          DateTime.tryParse(data["created_at"]?.toString() ?? "") ??
          DateTime.now(),
      timeScheduled: data["time_scheduled"]?.toString() ?? "",
      daysActive: data["days_active"]?.toString() ?? "",
      day: data["day"]?.toString() ?? "",
    );
  }
}
