class WorkerNotification {
  final String id;
  final String workerId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  WorkerNotification({
    required this.id,
    required this.workerId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory WorkerNotification.fromJson(Map<String, dynamic> json) {
    return WorkerNotification(
      id: json['id'],
      workerId: json['worker_id'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  WorkerNotification copyWith({bool? isRead}) {
    return WorkerNotification(
      id: id,
      workerId: workerId,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
