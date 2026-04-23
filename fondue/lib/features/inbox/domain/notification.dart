
class AppNotification {
  final String id;
  final String type; // e.g. system/admin/pet_match/chat/post
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    this.data = const {},
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    Map<String, dynamic> parsedData = const {};
    if (raw is Map<String, dynamic>) {
      parsedData = raw;
    } else if (raw is Map) {
      parsedData = Map<String, dynamic>.from(raw);
    }
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      time: DateTime.parse(json['created_at'] as String).toLocal(),
      isRead: json['is_read'] as bool? ?? false,
      data: parsedData,
    );
  }
}
