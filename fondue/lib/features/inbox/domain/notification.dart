
class AppNotification {
  final String id;
  final String type; // 'system' or 'admin'
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      time: DateTime.parse(json['created_at'] as String).toLocal(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}
