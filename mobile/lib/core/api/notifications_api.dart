import 'api_client.dart';

class NotificationsApi {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client.get(
      '/api/v1/notifications?limit=$limit&offset=$offset',
    );
    return response.data;
  }

  Future<int> getUnreadCount() async {
    final response = await _client.get(
      '/api/v1/notifications/unread-count',
    );
    return response.data['unread_count'] as int;
  }

  Future<void> markRead(String notificationId) async {
    await _client.put(
      '/api/v1/notifications/$notificationId/read',
    );
  }

  Future<void> markAllRead() async {
    await _client.put('/api/v1/notifications/read-all');
  }

  Future<void> deleteNotification(String notificationId) async {
    await _client.delete(
      '/api/v1/notifications/$notificationId',
    );
  }
}
