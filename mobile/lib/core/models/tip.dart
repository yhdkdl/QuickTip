import 'package:intl/intl.dart';

class TipHistoryItem {
  final String id;
  final double grossAmount;
  final double platformFee;
  final double workerPayout;
  final String paymentReference;
  final String initiatedVia;
  final DateTime createdAt;

  TipHistoryItem({
    required this.id,
    required this.grossAmount,
    required this.platformFee,
    required this.workerPayout,
    required this.paymentReference,
    required this.initiatedVia,
    required this.createdAt,
  });

  factory TipHistoryItem.fromJson(Map<String, dynamic> json) {
    return TipHistoryItem(
      id: json['id'],
      grossAmount: (json['gross_amount'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num).toDouble(),
      workerPayout: (json['worker_payout'] as num).toDouble(),
      paymentReference: json['payment_reference'],
      initiatedVia: json['initiated_via'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  String get formattedAmount {
    final f = NumberFormat('#,##0.00');
    return 'ETB ${f.format(workerPayout)}';
  }

  String get formattedDate {
    return DateFormat('MMM d, y · h:mm a').format(createdAt);
  }

  String get relativeDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(createdAt);
  }

  bool get isQr => initiatedVia == 'qr';
}

class PeriodEarnings {
  final double total;
  final int count;

  PeriodEarnings({required this.total, required this.count});

  factory PeriodEarnings.fromJson(Map<String, dynamic> json) {
    return PeriodEarnings(
      total: (json['total'] as num).toDouble(),
      count: json['count'] as int,
    );
  }

  String get formatted {
    final f = NumberFormat('#,##0.00');
    return 'ETB ${f.format(total)}';
  }
}

class EarningsSummary {
  final PeriodEarnings allTime;
  final PeriodEarnings today;
  final PeriodEarnings thisWeek;
  final PeriodEarnings thisMonth;
  final double averageTip;
  final double largestTip;

  EarningsSummary({
    required this.allTime,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.averageTip,
    required this.largestTip,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      allTime: PeriodEarnings.fromJson(json['all_time']),
      today: PeriodEarnings.fromJson(json['today']),
      thisWeek: PeriodEarnings.fromJson(json['this_week']),
      thisMonth: PeriodEarnings.fromJson(json['this_month']),
      averageTip: (json['average_tip'] as num).toDouble(),
      largestTip: (json['largest_tip'] as num).toDouble(),
    );
  }

  String get formattedAverage {
    final f = NumberFormat('#,##0.00');
    return 'ETB ${f.format(averageTip)}';
  }

  String get formattedLargest {
    final f = NumberFormat('#,##0.00');
    return 'ETB ${f.format(largestTip)}';
  }
}

class DashboardData {
  final EarningsSummary earnings;
  final List<TipHistoryItem> recentTips;

  DashboardData({
    required this.earnings,
    required this.recentTips,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      earnings: EarningsSummary.fromJson(json['earnings']),
      recentTips: (json['recent_tips'] as List)
          .map((t) => TipHistoryItem.fromJson(t))
          .toList(),
    );
  }
}
