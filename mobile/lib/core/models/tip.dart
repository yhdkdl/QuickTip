class Tip {
  final String id;
  final double grossAmount;
  final double platformFee;
  final double workerPayout;
  final String paymentReference;
  final DateTime createdAt;

  Tip({
    required this.id,
    required this.grossAmount,
    required this.platformFee,
    required this.workerPayout,
    required this.paymentReference,
    required this.createdAt,
  });

  factory Tip.fromJson(Map<String, dynamic> json) {
    return Tip(
      id: json['id'],
      grossAmount: (json['gross_amount'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num).toDouble(),
      workerPayout: (json['worker_payout'] as num).toDouble(),
      paymentReference: json['payment_reference'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class EarningsSummary {
  final double totalEarnings;
  final double todayEarnings;
  final double weekEarnings;
  final int totalTips;
  final List<Tip> recentTips;

  EarningsSummary({
    required this.totalEarnings,
    required this.todayEarnings,
    required this.weekEarnings,
    required this.totalTips,
    required this.recentTips,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: (json['total_earnings'] as num).toDouble(),
      todayEarnings: (json['today_earnings'] as num).toDouble(),
      weekEarnings: (json['week_earnings'] as num).toDouble(),
      totalTips: json['total_tips'] as int,
      recentTips: (json['recent_tips'] as List)
          .map((t) => Tip.fromJson(t))
          .toList(),
    );
  }
}
