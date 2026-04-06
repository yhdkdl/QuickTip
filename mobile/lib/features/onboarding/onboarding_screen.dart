import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

class _OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'Receive Tips Instantly',
      subtitle:
          'Your customers tip you directly via Chapa. Money goes straight to your Telebirr or bank account.',
      icon: Icons.bolt_rounded,
      iconColor: Color(0xFF00A651),
    ),
    _OnboardingPage(
      title: 'Your Personal QR Code',
      subtitle:
          'Display your unique QR code and customers scan it to tip you — no cash, no apps needed on their side.',
      icon: Icons.qr_code_rounded,
      iconColor: Color(0xFF6C63FF),
    ),
    _OnboardingPage(
      title: 'Tap to Tip with NFC',
      subtitle:
          'For face-to-face moments, just tap phones. The fastest tip experience ever built.',
      icon: Icons.contactless_rounded,
      iconColor: Color(0xFF00B4D8),
    ),
    _OnboardingPage(
      title: 'Track Your Earnings',
      subtitle:
          'See every tip in real time. Daily, weekly and all-time earnings at a glance.',
      icon: Icons.bar_chart_rounded,
      iconColor: Color(0xFFFF9500),
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
    if (mounted) context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),
            _buildBottomBar(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: page.iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(page.icon, size: 52, color: page.iconColor),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              _pages.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                width: i == _currentPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? AppConstants.brandGreen
                      : AppConstants.surface4,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: isLast
                ? _finish
                : () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppConstants.brandGreen,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.brandGreen.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
