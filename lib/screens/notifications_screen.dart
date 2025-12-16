import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifService = Provider.of<NotificationService>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: RefreshIndicator(
        onRefresh: () => notifService.fetchNotifications(),
        child: ListView.builder(
          itemCount: notifService.notifications.length,
          itemBuilder: (_, i) {
            final n = notifService.notifications[i];
            final isRead = n.readBy.contains(auth.userId);
            return ListTile(
              title: Text(n.title),
              subtitle: Text(n.message),
              trailing: isRead
                  ? null
                  : const Icon(Icons.circle, color: Colors.red, size: 12),
              onTap: () => notifService.markAsRead(n.id, auth.userId!),
            );
          },
        ),
      ),
    );
  }
}
