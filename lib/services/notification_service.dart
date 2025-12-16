import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_item.dart';

class NotificationService extends ChangeNotifier {
  final _client = Supabase.instance.client;
  List<NotificationItem> notifications = [];

  // Lấy danh sách notifications
  Future<void> fetchNotifications() async {
    try {
      final res = await _client
          .from('notifications')
          .select()
          .order('created_at', ascending: false);

      notifications = List<Map<String, dynamic>>.from(res)
          .map((e) => NotificationItem.fromMap(e))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi fetchNotifications: $e');
    }
  }

  // Gửi thông báo mới
  Future<void> sendNotification({
    required String title,
    required String message,
  }) async {
    try {
      await _client.from('notifications').insert({
        'title': title,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });

      await fetchNotifications(); // Cập nhật danh sách sau khi gửi
    } catch (e) {
      debugPrint('Lỗi gửi notification: $e');
    }
  }

  // Đánh dấu notification đã đọc
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      final notification =
          notifications.firstWhere((n) => n.id == notificationId);
      if (!notification.readBy.contains(userId)) {
        notification.readBy.add(userId);

        await _client
            .from('notifications')
            .update({'read_by': notification.readBy}).eq('id', notificationId);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi markAsRead: $e');
    }
  }
}
