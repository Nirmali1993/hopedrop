import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hopedrop/l10n/app_localizations.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String _foundEmail = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showError(l10n.pleaseEnterPhone);
      return;
    }
    if (phone.length < 9) {
      _showError(l10n.pleaseEnterPhone);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = await AuthService.resetPassword(phone);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _foundEmail = email;
          _emailSent = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'user-not-found') {
        _showError('No account found with this phone number');
      } else {
        _showError('Something went wrong. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Something went wrong. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB71C1C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _emailSent
            ? _SuccessView(
                email: _foundEmail,
                onBack: () => Navigator.pop(context),
              )
            : _FormView(
                phoneController: _phoneController,
                isLoading: _isLoading,
                onReset: _resetPassword,
              ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController phoneController;
  final bool isLoading;
  final VoidCallback onReset;

  const _FormView({
    required this.phoneController,
    required this.isLoading,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ NEW

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.lock_reset_outlined,
              color: Color(0xFFB71C1C), size: 36),
        ),
        const SizedBox(height: 24),

        // ✅ TRANSLATED
        Text(l10n.forgotPassword,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        Text(l10n.enterPhoneToReset,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF9E9E9E), height: 1.5)),
        const SizedBox(height: 32),

        // ✅ TRANSLATED
        Text(l10n.phoneNumber,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            // ✅ TRANSLATED
            hintText: l10n.enterPhoneNumber,
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon:
                const Icon(Icons.phone_outlined, color: Color(0xFFB71C1C)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFB71C1C), width: 1.5)),
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : onReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              disabledBackgroundColor:
                  const Color(0xFFB71C1C).withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                // ✅ TRANSLATED
                : Text(l10n.sendResetLink,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
          ),
        ),
        const SizedBox(height: 20),

        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text.rich(
              TextSpan(
                text: 'Remember your password? ',
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                children: [
                  TextSpan(
                    // ✅ TRANSLATED
                    text: l10n.login,
                    style: const TextStyle(
                        color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  final VoidCallback onBack;

  const _SuccessView({required this.email, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ NEW

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              color: Colors.green, size: 56),
        ),
        const SizedBox(height: 28),

        // ✅ TRANSLATED
        Text(l10n.resetSent,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 12),

        Text(
          'We\'ve sent a password reset link for the account linked to:',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('📧 $email',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB71C1C))),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF9E9E9E), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Check your email inbox and follow the link to reset your password.',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF9E9E9E), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            // ✅ TRANSLATED
            child: Text(l10n.login,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
