import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../l10n/app_localizations.dart'; // âœ… NEW
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'role_select_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.loginWithPhone(
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );

      try {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'fcmToken': token});
          }
        }
      } catch (e) {
        debugPrint('FCM token error: $e');
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _googleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.signInWithGoogle();

      try {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'fcmToken': token});
          }
        }
      } catch (e) {
        debugPrint('FCM token error: $e');
      }

      if (result != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // âœ… NEW
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo
                Center(child: _buildLogo()),
                const SizedBox(height: 40),

                // âœ… TRANSLATED Title
                Text(
                  l10n.login,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  // âœ… TRANSLATED subtitle
                  'Please fill up and login to your account',
                  style:
                      TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                ),
                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFB71C1C), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: Color(0xFFB71C1C), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // âœ… TRANSLATED Phone field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    hint: l10n.enterPhoneNumber,
                    suffix: const Icon(Icons.phone_outlined,
                        color: Color(0xFFBDBDBD)),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? l10n.pleaseEnterPhone : null,
                ),
                const SizedBox(height: 14),

                // âœ… TRANSLATED Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration(
                    hint: l10n.enterPassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFFBDBDBD),
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 6 ? l10n.passwordMinLength : null,
                ),
                const SizedBox(height: 8),

                // âœ… TRANSLATED Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: _redButtonStyle(),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(l10n.login,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 16),

                // âœ… TRANSLATED Forgot password
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    ),
                    child: Text.rich(
                      TextSpan(
                        text: '${l10n.forgotYourPassword} ',
                        style: const TextStyle(
                            color: Color(0xFF9E9E9E), fontSize: 14),
                        children: [
                          TextSpan(
                            text: l10n.resetHere,
                            style: const TextStyle(
                              color: Color(0xFFB71C1C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // OR divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                  ],
                ),
                const SizedBox(height: 20),

                // âœ… TRANSLATED Google Sign In
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isGoogleLoading ? null : _googleSignIn,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isGoogleLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(
                                  child: Text('G',
                                      style: TextStyle(
                                          color: Color(0xFF4285F4),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // âœ… TRANSLATED
                              Text(l10n.signInWithGoogle,
                                  style: const TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                // âœ… TRANSLATED Register link
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RoleSelectScreen()),
                    ),
                    child: Text.rich(
                      TextSpan(
                        text: '${l10n.dontHaveAccount} ',
                        style: const TextStyle(
                            color: Color(0xFF9E9E9E), fontSize: 14),
                        children: [
                          TextSpan(
                            text: l10n.signUp,
                            style: const TextStyle(
                                color: Color(0xFFB71C1C),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffix,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1.5)),
    );
  }

  ButtonStyle _redButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      );

  Widget _buildLogo() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Hope',
            style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
        Text('Dr',
            style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB71C1C))),
        Icon(Icons.water_drop, color: Color(0xFFB71C1C), size: 26),
        Text('p',
            style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB71C1C))),
      ],
    );
  }
}
