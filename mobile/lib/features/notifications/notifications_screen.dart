import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/notifications_api.dart';
import '../../core/models/notification.dart';
import '../../core/services/websocket_service.dart';
import '../../core/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final NotificationsApi _api = NotificationsApi();

  List<WorkerNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.getNotifications();
      final list = (data['notifications'] as List)
          .map((n) => WorkerNotification.fromJson(n))
          .toList();

      final unreadCount = data['unread_count'] as int;

      if (mounted) {
        setState(() {
          _notifications = list;
          _loading = false;
        });
        context
            .read<WebSocketService>()
            .setUnreadCount(unreadCount);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notifications';
          _loading = false;
        });
      }
    }
  }

  Future<void> _markRead(WorkerNotification notification) async {
    if (notification.isRead) return;

    try {
      await _api.markRead(notification.id);

      setState(() {
        final index = _notifications
            .indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] =
              notification.copyWith(isRead: true);
        }
      });

      context.read<WebSocketService>().decrementUnread();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllRead();
      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
      });
      context.read<WebSocketService>().clearUnread();
    } catch (_) {}
  }

  Future<void> _delete(WorkerNotification notification) async {
    try {
      await _api.deleteNotification(notification.id);
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
      if (!notification.isRead) {
        context.read<WebSocketService>().decrementUnread();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        context.watch<WebSocketService>().unreadCount;

    return Scaffold(
      backgroundColor: AppConstants.surface,
      appBar: AppBar(
        backgroundColor: AppConstants.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppConstants.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.brandGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: AppConstants.brandGreen,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppConstants.brandGreen,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppConstants.errorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.brandGreen,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: AppConstants.textMuted,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will be notified when you receive a tip',
              style: TextStyle(
                color: AppConstants.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppConstants.brandGreen,
      backgroundColor: AppConstants.surface2,
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) =>
            _buildNotificationItem(_notifications[index]),
      ),
    );
  }

  Widget _buildNotificationItem(WorkerNotification notification) {
    final isTip = notification.title.contains('Tip');

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(notification),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppConstants.errorColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppConstants.errorColor,
        ),
      ),
      child: GestureDetector(
        onTap: () => _markRead(notification),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppConstants.surface2
                : AppConstants.brandGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? AppConstants.borderColor
                  : AppConstants.brandGreen.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isTip
                      ? AppConstants.brandGreen.withOpacity(0.15)
                      : AppConstants.surface3,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isTip
                      ? Icons.payments_rounded
                      : Icons.notifications_rounded,
                  color: isTip
                      ? AppConstants.brandGreen
                      : AppConstants.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppConstants.brandGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.timeAgo,
                      style: TextStyle(
                        color: AppConstants.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
