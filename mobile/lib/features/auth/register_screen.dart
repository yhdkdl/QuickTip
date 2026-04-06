import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _professionController = TextEditingController();
  final _telebirrPhoneController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  String _payoutMethod = 'telebirr';
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _professionController.dispose();
    _telebirrPhoneController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0') && digits.length == 10) {
      return '251${digits.substring(1)}';
    }
    return digits;
  }

  Map<String, dynamic> _buildPayoutData() {
    if (_payoutMethod == 'telebirr') {
      return {
        'method': 'telebirr',
        'telebirr_phone': _normalizePhone(
          _telebirrPhoneController.text.trim(),
        ),
      };
    }
    return {
      'method': 'bank',
      'bank_name': _bankNameController.text.trim(),
      'account_number': _accountNumberController.text.trim(),
      'account_name': _accountNameController.text.trim(),
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text.trim(),
      phone: _normalizePhone(_phoneController.text.trim()),
      password: _passwordController.text,
      profession: _professionController.text.trim(),
      payout: _buildPayoutData(),
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: AppConstants.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppConstants.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildStepIndicator(),
                const SizedBox(height: 32),
                if (_currentStep == 0) _buildPersonalDetails(),
                if (_currentStep == 1) _buildPayoutDetails(),
                const SizedBox(height: 32),
                if (_currentStep == 0)
                  PrimaryButton(
                    label: 'Continue',
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _currentStep = 1);
                      }
                    },
                    icon: Icons.arrow_forward_rounded,
                  ),
                if (_currentStep == 1)
                  Column(
                    children: [
                      PrimaryButton(
                        label: 'Create Account',
                        onPressed: _submit,
                        loading: auth.loading,
                        icon: Icons.check_rounded,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            setState(() => _currentStep = 0),
                        child: Text(
                          'Back to personal details',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                if (_currentStep == 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppConstants.brandGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppConstants.brandGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QuickTip',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Create your worker account',
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStep(0, 'Personal Details'),
        Expanded(
          child: Container(
            height: 1,
            color: _currentStep >= 1
                ? AppConstants.brandGreen
                : AppConstants.borderColor,
          ),
        ),
        _buildStep(1, 'Payout Setup'),
      ],
    );
  }

  Widget _buildStep(int step, String label) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone || isActive
                ? AppConstants.brandGreen
                : AppConstants.surface3,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone || isActive
                  ? AppConstants.brandGreen
                  : AppConstants.borderColor,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  )
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : AppConstants.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? AppConstants.textPrimary
                : AppConstants.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDetails() {
    return Column(
      children: [
        CustomTextField(
          label: 'Full Name',
          hint: 'Abebe Girma',
          controller: _nameController,
          prefixIcon: Icon(
            Icons.person_outline_rounded,
            color: AppConstants.textMuted,
            size: 20,
          ),
          validator: (v) => v == null || v.trim().length < 2
              ? 'Name must be at least 2 characters'
              : null,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Phone Number',
          hint: '09XX XXX XXXX',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icon(
            Icons.phone_outlined,
            color: AppConstants.textMuted,
            size: 20,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Phone is required';
            final digits = v.replaceAll(RegExp(r'\D'), '');
            if (!RegExp(r'^(09|07)\d{8}$').hasMatch(digits)) {
              return 'Enter a valid Ethiopian phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Profession',
          hint: 'Taxi Driver, Waiter, Barber...',
          controller: _professionController,
          prefixIcon: Icon(
            Icons.work_outline_rounded,
            color: AppConstants.textMuted,
            size: 20,
          ),
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Password',
          hint: 'At least 8 characters',
          controller: _passwordController,
          isPassword: true,
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: AppConstants.textMuted,
            size: 20,
          ),
          validator: (v) => v == null || v.length < 8
              ? 'Password must be at least 8 characters'
              : null,
        ),
      ],
    );
  }

  Widget _buildPayoutDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How do you want to receive tips?',
          style: TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildMethodCard(
              'telebirr',
              'Telebirr',
              Icons.phone_android_rounded,
              const Color(0xFF00A651),
            ),
            const SizedBox(width: 12),
            _buildMethodCard(
              'bank',
              'Bank Transfer',
              Icons.account_balance_outlined,
              const Color(0xFF6C63FF),
            ),
          ],
        ),
        const SizedBox(height: 28),
        if (_payoutMethod == 'telebirr')
          CustomTextField(
            label: 'Telebirr Phone Number',
            hint: '09XX XXX XXXX',
            controller: _telebirrPhoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: AppConstants.textMuted,
              size: 20,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Telebirr phone is required';
              }
              final digits = v.replaceAll(RegExp(r'\D'), '');
              if (!RegExp(r'^(09|07)\d{8}$').hasMatch(digits)) {
                return 'Enter a valid Ethiopian phone number';
              }
              return null;
            },
          ),
        if (_payoutMethod == 'bank') ...[
          CustomTextField(
            label: 'Bank Name',
            hint: 'Commercial Bank of Ethiopia',
            controller: _bankNameController,
            prefixIcon: Icon(
              Icons.account_balance_outlined,
              color: AppConstants.textMuted,
              size: 20,
            ),
            validator: (v) => v == null || v.isEmpty
                ? 'Bank name is required'
                : null,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Account Number',
            hint: '1000123456789',
            controller: _accountNumberController,
            keyboardType: TextInputType.number,
            prefixIcon: Icon(
              Icons.tag_rounded,
              color: AppConstants.textMuted,
              size: 20,
            ),
            validator: (v) => v == null || v.isEmpty
                ? 'Account number is required'
                : null,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Account Holder Name',
            hint: 'Full name on the account',
            controller: _accountNameController,
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: AppConstants.textMuted,
              size: 20,
            ),
            validator: (v) => v == null || v.isEmpty
                ? 'Account name is required'
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildMethodCard(
    String method,
    String label,
    IconData icon,
    Color color,
  ) {
    final selected = _payoutMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _payoutMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.12)
                : AppConstants.surface3,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : AppConstants.borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : AppConstants.textMuted, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? color : AppConstants.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
