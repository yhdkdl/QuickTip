import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';
import 'notification_service.dart';

class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance =
      WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocket? _socket;
  int _unreadCount = 0;
  bool _connected = false;
  Timer? _reconnectTimer;

  int get unreadCount => _unreadCount;
  bool get connected => _connected;

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  Future<void> connect(String workerId) async {
    if (_connected) return;

    final wsUrl = AppConstants.baseUrl
        .replaceFirst('http', 'ws');

    try {
      _socket = await WebSocket.connect(
        '$wsUrl/ws/worker/$workerId',
      );

      _connected = true;
      notifyListeners();

      _socket!.listen(
        (data) {
          _handleMessage(data);
        },
        onDone: () {
          _connected = false;
          notifyListeners();
          _scheduleReconnect(workerId);
        },
        onError: (error) {
          _connected = false;
          notifyListeners();
          _scheduleReconnect(workerId);
        },
        cancelOnError: true,
      );

    } catch (e) {
      _scheduleReconnect(workerId);
    }
  }

  void _handleMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String);
      final type = data['type'] as String;

      if (type == 'notification') {
        final title = data['title'] as String;
        final message = data['message'] as String;

        _unreadCount += 1;
        notifyListeners();

        NotificationService().showTipNotification(
          title: title,
          message: message,
        );
      }
    } catch (_) {}
  }

  void _scheduleReconnect(String workerId) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      const Duration(seconds: 5),
      () => connect(workerId),
    );
  }

  void setUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  void decrementUnread() {
    if (_unreadCount > 0) {
      _unreadCount -= 1;
      notifyListeners();
    }
  }

  void clearUnread() {
    _unreadCount = 0;
    notifyListeners();
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.close();
    _socket = null;
    _connected = false;
    _unreadCount = 0;
  }
}
