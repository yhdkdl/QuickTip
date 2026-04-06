import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../core/auth/auth_provider.dart';
import '../../core/api/worker_api.dart';
import '../../core/constants.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen>
    with SingleTickerProviderStateMixin {
  final WorkerApi _workerApi = WorkerApi();
  final GlobalKey _qrKey = GlobalKey();

  String? _tipUrl;
  String? _qrCodeUrl;
  bool _loading = false;
  bool _generating = false;
  String? _error;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _initialize();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _loading = true);

    final worker = context.read<AuthProvider>().worker;

    if (worker == null) {
      setState(() {
        _error = 'Worker not found';
        _loading = false;
      });
      return;
    }

    if (worker.hasQrCode) {
      final workerId = worker.id;
      final frontendUrl = 'http://localhost:3000';
      setState(() {
        _qrCodeUrl = worker.qrCodeUrl;
        _tipUrl = '$frontendUrl/tip/$workerId';
        _loading = false;
      });
    } else {
      await _generateQr();
    }
  }

  Future<void> _generateQr() async {
    setState(() => _generating = true);

    try {
      final result = await _workerApi.generateQr();
      final auth = context.read<AuthProvider>();

      setState(() {
        _qrCodeUrl = result['qr_code_url'];
        _tipUrl = result['tip_url'];
        _generating = false;
        _loading = false;
      });

      await auth.checkAuthStatus();
    } catch (e) {
      setState(() {
        _error = 'Failed to generate QR code. Please try again.';
        _generating = false;
        _loading = false;
      });
    }
  }

  Future<void> _shareQr() async {
    if (_tipUrl == null) return;
    await Clipboard.setData(ClipboardData(text: _tipUrl!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tip link copied to clipboard'),
        backgroundColor: AppConstants.brandGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Copy',
          textColor: Colors.white,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _tipUrl!));
          },
        ),
      ),
    );
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
          'My QR Code',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_tipUrl != null)
            IconButton(
              icon: Icon(
                Icons.share_rounded,
                color: AppConstants.textSecondary,
              ),
              onPressed: _shareQr,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading || _generating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: AppConstants.brandGreen,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _generating ? 'Generating your QR code...' : 'Loading...',
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
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
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _generateQr,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.brandGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_tipUrl == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildWorkerBadge(),
          const SizedBox(height: 32),
          _buildQrCard(),
          const SizedBox(height: 24),
          _buildTipUrlCard(),
          const SizedBox(height: 32),
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildWorkerBadge() {
    final worker = context.read<AuthProvider>().worker;
    if (worker == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF007A3D), Color(0xFF00A651)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              worker.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              worker.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (worker.profession != null)
              Text(
                worker.profession!,
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQrCard() {
    return RepaintBoundary(
      key: _qrKey,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppConstants.brandGreen.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              ),
              child: QrImageView(
                data: _tipUrl!,
                version: QrVersions.auto,
                size: 220,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0F0F0F),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0F0F0F),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppConstants.brandGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'QuickTip',
                  style: TextStyle(
                    color: AppConstants.surface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipUrlCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surface3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link_rounded,
            color: AppConstants.brandGreen,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _tipUrl!,
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _shareQr,
            child: Icon(
              Icons.copy_rounded,
              color: AppConstants.textMuted,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        children: [
          _buildInstructionRow(
            '1',
            'Show this QR code to your customer',
            Icons.phone_android_rounded,
          ),
          const SizedBox(height: 16),
          _buildInstructionRow(
            '2',
            'They scan it with their phone camera',
            Icons.qr_code_scanner_rounded,
          ),
          const SizedBox(height: 16),
          _buildInstructionRow(
            '3',
            'They enter the tip amount and pay via Chapa',
            Icons.payments_rounded,
          ),
          const SizedBox(height: 16),
          _buildInstructionRow(
            '4',
            'Money goes directly to your payout account',
            Icons.account_balance_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(
    String step,
    String text,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppConstants.brandGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                color: AppConstants.brandGreen,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: AppConstants.textMuted, size: 18),
      ],
    );
  }
}
