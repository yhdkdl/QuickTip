import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:async';
import '../../core/auth/auth_provider.dart';
import '../../core/constants.dart';

enum NfcState {
  checking,
  unavailable,
  ready,
  tapping,
  success,
  error,
}

class NfcScreen extends StatefulWidget {
  const NfcScreen({super.key});

  @override
  State<NfcScreen> createState() => _NfcScreenState();
}

class _NfcScreenState extends State<NfcScreen> with TickerProviderStateMixin {
  NfcState _nfcState = NfcState.checking;
  String? _errorMessage;
  bool _isActive = false;

  late AnimationController _rippleController;
  late AnimationController _iconController;
  late Animation<double> _ripple1;
  late Animation<double> _ripple2;
  late Animation<double> _ripple3;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkNfcAvailability();
  }

  void _setupAnimations() {
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _ripple1 = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _ripple2 = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
      ),
    );

    _ripple3 = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _iconScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.elasticOut,
      ),
    );
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;

      if (availability == NFCAvailability.available) {
        setState(() => _nfcState = NfcState.ready);
      } else if (availability == NFCAvailability.disabled) {
        setState(() {
          _nfcState = NfcState.unavailable;
          _errorMessage = 'NFC is disabled on your device. '
              'Please enable it in Settings.';
        });
      } else {
        setState(() {
          _nfcState = NfcState.unavailable;
          _errorMessage = 'This device does not support NFC.';
        });
      }
    } catch (e) {
      setState(() {
        _nfcState = NfcState.unavailable;
        _errorMessage = 'Could not check NFC availability.';
      });
    }
  }

  Future<void> _startNfcTap() async {
    final worker = context.read<AuthProvider>().worker;
    if (worker == null) return;

    final tipUrl = 'http://localhost:3000/tip/${worker.id}';

    setState(() {
      _nfcState = NfcState.tapping;
      _isActive = true;
    });

    _rippleController.repeat();

    try {
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 30),
        iosMultipleTagMessage: 'Multiple tags found, please use one tag.',
        iosAlertMessage: 'Hold near customer phone to share tip link',
      );

      await FlutterNfcKit.transceive(
        'D1010E55036C6F63616C686F73743A333030302F74697'
        '0/${worker.id}',
      );

      await FlutterNfcKit.finish(
        iosAlertMessage: 'Tip link shared successfully!',
      );

      setState(() => _nfcState = NfcState.success);
      _rippleController.stop();
      _rippleController.reset();
      _iconController.forward();

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _nfcState = NfcState.ready;
          _isActive = false;
        });
        _iconController.reset();
      }
    } catch (e) {
      await FlutterNfcKit.finish(
        iosErrorMessage: 'Tap failed. Please try again.',
      );

      _rippleController.stop();
      _rippleController.reset();

      if (mounted) {
        final errorStr = e.toString();
        if (errorStr.contains('timeout') || errorStr.contains('UserCancel')) {
          setState(() {
            _nfcState = NfcState.ready;
            _isActive = false;
          });
        } else {
          setState(() {
            _nfcState = NfcState.error;
            _errorMessage = 'NFC tap failed. Please try again.';
            _isActive = false;
          });
        }
      }
    }
  }

  void _stopNfc() async {
    try {
      await FlutterNfcKit.finish();
    } catch (_) {}
    _rippleController.stop();
    _rippleController.reset();
    if (mounted) {
      setState(() {
        _nfcState = NfcState.ready;
        _isActive = false;
      });
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _iconController.dispose();
    if (_isActive) FlutterNfcKit.finish().catchError((_) {});
    super.dispose();
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
          onPressed: () {
            if (_isActive) _stopNfc();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'NFC Tap to Tip',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_nfcState) {
      case NfcState.checking:
        return _buildChecking();
      case NfcState.unavailable:
        return _buildUnavailable();
      case NfcState.ready:
        return _buildReady();
      case NfcState.tapping:
        return _buildTapping();
      case NfcState.success:
        return _buildSuccess();
      case NfcState.error:
        return _buildError();
    }
  }

  Widget _buildChecking() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppConstants.brandGreen),
          const SizedBox(height: 20),
          Text(
            'Checking NFC...',
            style: TextStyle(color: AppConstants.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppConstants.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.nfc_rounded,
                color: AppConstants.errorColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'NFC Not Available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'NFC is not available on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.surface2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppConstants.borderColor),
              ),
              child: Column(
                children: [
                  Text(
                    'Use your QR code instead',
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.qr_code_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Show QR Code',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.brandGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReady() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildNfcCircle(
            color: AppConstants.brandGreen,
            icon: Icons.contactless_rounded,
            subtitle: 'Ready to tap',
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _startNfcTap,
              icon: const Icon(
                Icons.contactless_rounded,
                color: Colors.white,
                size: 22,
              ),
              label: const Text(
                'Start NFC Tap Mode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.brandGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildHowItWorks(),
        ],
      ),
    );
  }

  Widget _buildTapping() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _rippleController,
          builder: (_, child) {
            return SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildRipple(_ripple3, 0.15),
                  _buildRipple(_ripple2, 0.20),
                  _buildRipple(_ripple1, 0.25),
                  child!,
                ],
              ),
            );
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppConstants.brandGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.brandGreen.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.contactless_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          'Hold near customer\'s phone',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Waiting for NFC contact...',
          style: TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 48),
        TextButton.icon(
          onPressed: _stopNfc,
          icon: Icon(
            Icons.close_rounded,
            color: AppConstants.textMuted,
            size: 18,
          ),
          label: Text(
            'Cancel',
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRipple(Animation<double> animation, double opacity) {
    return Transform.scale(
      scale: animation.value,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppConstants.brandGreen.withOpacity(
            opacity * (1 - animation.value + 0.6).clamp(0.0, 1.0),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _iconScale,
            builder: (_, child) => Transform.scale(
              scale: _iconScale.value,
              child: child,
            ),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppConstants.brandGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.brandGreen.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Tip link shared!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The customer\'s phone will open\nthe tip page automatically',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready for next tap in 3 seconds...',
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 13,
            ),
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
              size: 56,
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => setState(() {
                _nfcState = NfcState.ready;
                _errorMessage = null;
              }),
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

  Widget _buildNfcCircle({
    required Color color,
    required IconData icon,
    required String subtitle,
  }) {
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(icon, color: color, size: 64),
        ),
        const SizedBox(height: 16),
        Text(
          subtitle,
          style: TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW IT WORKS',
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildStep('Tap Start NFC Tap Mode', Icons.touch_app_rounded),
          const SizedBox(height: 12),
          _buildStep(
            'Hold your phone near the customer\'s phone',
            Icons.phone_android_rounded,
          ),
          const SizedBox(height: 12),
          _buildStep(
            'Their browser opens your tip page automatically',
            Icons.open_in_browser_rounded,
          ),
          const SizedBox(height: 12),
          _buildStep(
            'They complete payment — you receive a notification',
            Icons.notifications_active_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.brandGreen, size: 20),
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
      ],
    );
  }
}
