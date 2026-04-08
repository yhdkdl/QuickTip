import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/api/dashboard_api.dart';
import '../../core/models/tip.dart';
import '../../core/constants.dart';
import '../../core/api/notifications_api.dart';
import '../../core/services/websocket_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DashboardApi _api = DashboardApi();
  final NotificationsApi _notificationsApi = NotificationsApi();
  DashboardData? _data;
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationsApi.getUnreadCount();
      if (mounted) {
        context.read<WebSocketService>().setUnreadCount(count);
      }
    } catch (_) {}
  }

  Future<void> _loadDashboard() async {
    try {
      final result = await _api.getEarnings();
      if (mounted) {
        setState(() {
          _data = DashboardData.fromJson(result);
          _loadingData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final worker = auth.worker;

    if (worker == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppConstants.surface,
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: AppConstants.brandGreen,
        backgroundColor: AppConstants.surface2,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context, worker.initials),
                const SizedBox(height: 28),
                _buildGreeting(worker.name, worker.profession),
                const SizedBox(height: 24),
                _buildEarningsCard(),
                const SizedBox(height: 20),
                _buildQuickActions(context),
                const SizedBox(height: 28),
                _buildRecentActivity(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String initials) {
    final unreadCount = context.watch<WebSocketService>().unreadCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppConstants.brandGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'QuickTip',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppConstants.surface3,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppConstants.borderColor,
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppConstants.textSecondary,
                      size: 20,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppConstants.brandGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppConstants.surface,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await context.read<AuthProvider>().logout();
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppConstants.surface3,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.borderColor,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting(String name, String? profession) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final firstName = name.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $firstName 👋',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        if (profession != null) ...[
          const SizedBox(height: 4),
          Text(
            profession,
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEarningsCard() {
    final f = NumberFormat('#,##0.00');
    final allTime = _data?.earnings.allTime;
    final today = _data?.earnings.today;
    final week = _data?.earnings.thisWeek;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007A3D), Color(0xFF00A651)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A651).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Earnings',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'All time',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _loadingData
              ? const SizedBox(
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : Text(
                  'ETB ${f.format(allTime?.total ?? 0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat(
                'Today',
                _loadingData ? '...' : 'ETB ${f.format(today?.total ?? 0)}',
              ),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 32,
                color: Colors.white24,
              ),
              const SizedBox(width: 16),
              _buildMiniStat(
                'This Week',
                _loadingData ? '...' : 'ETB ${f.format(week?.total ?? 0)}',
              ),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 32,
                color: Colors.white24,
              ),
              const SizedBox(width: 16),
              _buildMiniStat(
                'Tips',
                _loadingData ? '...' : '${allTime?.count ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: TextStyle(
            color: AppConstants.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionCard(
              icon: Icons.qr_code_rounded,
              label: 'My QR Code',
              color: const Color(0xFF6C63FF),
              onTap: () => context.push('/qr'),
            ),
            const SizedBox(width: 12),
            _buildActionCard(
              icon: Icons.contactless_rounded,
              label: 'NFC Tap',
              color: const Color(0xFF00B4D8),
              onTap: () => context.push('/nfc'),
            ),
            const SizedBox(width: 12),
            _buildActionCard(
              icon: Icons.bar_chart_rounded,
              label: 'Earnings',
              color: const Color(0xFFFF9500),
              onTap: () => context.push('/earnings'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppConstants.surface2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT TIPS',
              style: TextStyle(
                color: AppConstants.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/earnings'),
              child: Text(
                'See all',
                style: TextStyle(
                  color: AppConstants.brandGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingData)
          _buildShimmerList()
        else if (_data == null || _data!.recentTips.isEmpty)
          _buildEmptyState()
        else
          Column(
            children: _data!.recentTips
                .map((tip) => _buildRecentTipItem(tip))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildShimmerList() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 72,
          decoration: BoxDecoration(
            color: AppConstants.surface2,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            'No tips yet',
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Share your QR code to start\nreceiving tips',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTipItem(TipHistoryItem tip) {
    final f = NumberFormat('#,##0.00');

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppConstants.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tip.isQr
                  ? const Color(0xFF6C63FF).withOpacity(0.12)
                  : const Color(0xFF00B4D8).withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              tip.isQr ? Icons.qr_code_rounded : Icons.contactless_rounded,
              color:
                  tip.isQr ? const Color(0xFF6C63FF) : const Color(0xFF00B4D8),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ETB ${f.format(tip.workerPayout)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  tip.relativeDate,
                  style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppConstants.brandGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tip.isQr ? 'QR' : 'NFC',
              style: TextStyle(
                color: AppConstants.brandGreen,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
