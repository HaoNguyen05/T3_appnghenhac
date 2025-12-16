class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final List<String> readBy;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.readBy,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      createdAt: DateTime.parse(map['created_at']),
      readBy: List<String>.from(map['read_by'] ?? []),
    );
  }
}
