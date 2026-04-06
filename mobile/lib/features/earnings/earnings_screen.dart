import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/dashboard_api.dart';
import '../../core/models/tip.dart';
import '../../core/constants.dart';

enum EarningsPeriod { today, week, month, allTime }

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final DashboardApi _api = DashboardApi();
  final ScrollController _scrollController = ScrollController();

  DashboardData? _data;
  bool _loading = true;
  bool _error = false;

  EarningsPeriod _selectedPeriod = EarningsPeriod.allTime;

  List<TipHistoryItem> _allTips = [];
  int _currentPage = 1;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTips();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final result = await _api.getEarnings();
      final data = DashboardData.fromJson(result);

      final historyResult = await _api.getTipHistory(page: 1);
      final tips = (historyResult['tips'] as List)
          .map((t) => TipHistoryItem.fromJson(t))
          .toList();

      setState(() {
        _data = data;
        _allTips = tips;
        _hasMore = historyResult['has_more'] as bool;
        _currentPage = 1;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _loadMoreTips() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final result = await _api.getTipHistory(page: nextPage);
      final tips = (result['tips'] as List)
          .map((t) => TipHistoryItem.fromJson(t))
          .toList();

      setState(() {
        _allTips.addAll(tips);
        _hasMore = result['has_more'] as bool;
        _currentPage = nextPage;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  PeriodEarnings get _currentPeriod {
    if (_data == null) {
      return PeriodEarnings(total: 0, count: 0);
    }
    switch (_selectedPeriod) {
      case EarningsPeriod.today:
        return _data!.earnings.today;
      case EarningsPeriod.week:
        return _data!.earnings.thisWeek;
      case EarningsPeriod.month:
        return _data!.earnings.thisMonth;
      case EarningsPeriod.allTime:
        return _data!.earnings.allTime;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Earnings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppConstants.textSecondary,
            ),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? _buildLoading()
          : _error
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppConstants.brandGreen,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading your earnings...',
            style: TextStyle(color: AppConstants.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Could not load earnings',
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.brandGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppConstants.brandGreen,
      backgroundColor: AppConstants.surface2,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildMainEarningsCard(),
                  const SizedBox(height: 16),
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),
                  _buildStatsRow(),
                  const SizedBox(height: 28),
                  _buildSectionHeader('TIP HISTORY'),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          _allTips.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyTips())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _allTips.length) {
                        return _buildLoadMoreIndicator();
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: _buildTipItem(_allTips[index]),
                      );
                    },
                    childCount: _allTips.length + (_hasMore ? 1 : 0),
                  ),
                ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildMainEarningsCard() {
    final f = NumberFormat('#,##0.00');
    final period = _currentPeriod;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007A3D), Color(0xFF00A651)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppConstants.brandGreen.withOpacity(0.25),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _periodLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ETB ${f.format(period.total)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${period.count} tip${period.count == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case EarningsPeriod.today:
        return 'Today\'s Earnings';
      case EarningsPeriod.week:
        return 'This Week\'s Earnings';
      case EarningsPeriod.month:
        return 'This Month\'s Earnings';
      case EarningsPeriod.allTime:
        return 'Total Earnings';
    }
  }

  Widget _buildPeriodSelector() {
    final periods = [
      (EarningsPeriod.today, 'Today'),
      (EarningsPeriod.week, 'Week'),
      (EarningsPeriod.month, 'Month'),
      (EarningsPeriod.allTime, 'All Time'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppConstants.surface3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        children: periods.map((entry) {
          final isSelected = _selectedPeriod == entry.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(
                () => _selectedPeriod = entry.$1,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppConstants.brandGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  entry.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        isSelected ? Colors.white : AppConstants.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow() {
    if (_data == null) return const SizedBox.shrink();

    return Row(
      children: [
        _buildStatCard(
          'Average Tip',
          _data!.earnings.formattedAverage,
          Icons.trending_up_rounded,
          const Color(0xFF6C63FF),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Largest Tip',
          _data!.earnings.formattedLargest,
          Icons.emoji_events_rounded,
          const Color(0xFFFF9500),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.surface2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppConstants.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppConstants.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppConstants.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        Text(
          '${_data?.earnings.allTime.count ?? 0} total',
          style: TextStyle(
            color: AppConstants.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(TipHistoryItem tip) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: AppConstants.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tip.isQr
                  ? const Color(0xFF6C63FF).withOpacity(0.12)
                  : const Color(0xFF00B4D8).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              tip.isQr ? Icons.qr_code_rounded : Icons.contactless_rounded,
              color:
                  tip.isQr ? const Color(0xFF6C63FF) : const Color(0xFF00B4D8),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.formattedAmount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tip.relativeDate,
                  style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.brandGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Received',
                  style: TextStyle(
                    color: AppConstants.brandGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tip.isQr ? 'via QR' : 'via NFC',
                style: TextStyle(
                  color: AppConstants.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTips() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppConstants.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppConstants.borderColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              color: AppConstants.textMuted,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'No tips yet',
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Share your QR code to start\nreceiving tips',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppConstants.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: _loadingMore
            ? CircularProgressIndicator(
                color: AppConstants.brandGreen,
                strokeWidth: 2,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
