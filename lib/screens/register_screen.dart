import 'package:flutter/material.dart';
import 'package:hopedrop/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _selectedBloodType;
  String? _errorMessage;
  DateTime? _lastDonationDate;
  bool _hasNeverDonated = true;

  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickLastDonationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 100)),
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFB71C1C),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _lastDonationDate = picked);
    }
  }

  String? _validateDonorEligibility() {
    final l10n = AppLocalizations.of(context)!;
    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 18) return '❌ ${l10n.notEligibleAge}';

    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight < 50) return '❌ ${l10n.notEligibleWeight}';

    if (!_hasNeverDonated && _lastDonationDate != null) {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      if (_lastDonationDate!.isAfter(threeMonthsAgo)) {
        return '❌ ${l10n.notEligibleDonation}';
      }
    }
    return null;
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.role == 'donor') {
      final eligibilityError = _validateDonorEligibility();
      if (eligibilityError != null) {
        setState(() => _errorMessage = eligibilityError);
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.registerWithPhone(
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        bloodType: _selectedBloodType ?? '',
        role: widget.role,
        age: widget.role == 'donor'
            ? int.tryParse(_ageController.text.trim())
            : null,
        weight: widget.role == 'donor'
            ? double.tryParse(_weightController.text.trim())
            : null,
        lastDonationDate: widget.role == 'donor' && !_hasNeverDonated
            ? _lastDonationDate
            : null,
      );

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ NEW
    final isDonor = widget.role == 'donor';

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
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: Color(0xFF1A1A1A)),
                  ),
                ),
                const SizedBox(height: 28),

                // ✅ TRANSLATED Title
                Text(
                  isDonor ? l10n.registerAsDonor : l10n.registerAsRecipient,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 4),
                // ✅ TRANSLATED
                Text(l10n.fillDetails,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF9E9E9E))),
                const SizedBox(height: 20),

                // Role badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDonor
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDonor ? Icons.volunteer_activism : Icons.search,
                        size: 16,
                        color: isDonor ? const Color(0xFFB71C1C) : Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      // ✅ TRANSLATED
                      Text(
                        isDonor ? l10n.bloodDonor : l10n.bloodRecipient,
                        style: TextStyle(
                          color:
                              isDonor ? const Color(0xFFB71C1C) : Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Error box
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              const Color(0xFFB71C1C).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFB71C1C), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: const TextStyle(
                                  color: Color(0xFFB71C1C), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                // ✅ TRANSLATED Eligibility info box
                if (isDonor)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.info_outline,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text(l10n.eligibilityRequirements,
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ]),
                        const SizedBox(height: 6),
                        Text('✅  ${l10n.ageMustBe18}',
                            style: const TextStyle(
                                color: Colors.green, fontSize: 12)),
                        Text('✅  ${l10n.weightMustBe50}',
                            style: const TextStyle(
                                color: Colors.green, fontSize: 12)),
                        Text('✅  ${l10n.lastDonation3Months}',
                            style: const TextStyle(
                                color: Colors.green, fontSize: 12)),
                      ],
                    ),
                  ),

                // ✅ TRANSLATED Full name
                _buildField(
                  controller: _nameController,
                  hint: l10n.fullName,
                  icon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 14),

                // ✅ TRANSLATED Email
                _buildField(
                  controller: _emailController,
                  hint: l10n.emailAddress,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Please enter your email';
                    if (!v.contains('@') || !v.contains('.'))
                      return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ✅ TRANSLATED Phone
                _buildField(
                  controller: _phoneController,
                  hint: l10n.phoneNumber,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Please enter your phone number'
                      : null,
                ),
                const SizedBox(height: 14),

                // ✅ TRANSLATED Blood type
                DropdownButtonFormField<String>(
                  initialValue: _selectedBloodType,
                  decoration: _inputDecoration(
                      hint: l10n.bloodType, icon: Icons.water_drop_outlined),
                  items: _bloodTypes
                      .map((bt) => DropdownMenuItem(value: bt, child: Text(bt)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBloodType = v),
                  validator: (v) => v == null ? l10n.selectBloodType : null,
                ),
                const SizedBox(height: 14),

                // ✅ TRANSLATED Donor-only fields
                if (isDonor) ...[
                  _buildField(
                    controller: _ageController,
                    hint: l10n.age,
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Please enter your age';
                      final age = int.tryParse(v);
                      if (age == null) return 'Please enter a valid age';
                      if (age < 18) return '❌ ${l10n.notEligibleAge}';
                      if (age > 65) return '❌ Age must be 65 or younger.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(
                      hint: l10n.weight,
                      icon: Icons.monitor_weight_outlined,
                    ).copyWith(
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('KG',
                            style: TextStyle(
                                color: Color(0xFFB71C1C),
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Please enter your weight';
                      final weight = double.tryParse(v);
                      if (weight == null) return 'Please enter a valid weight';
                      if (weight < 50) return '❌ ${l10n.notEligibleWeight}';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // ✅ TRANSLATED Last donation date
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.lastDonationDate,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 10),

                        // ✅ TRANSLATED Never donated checkbox
                        GestureDetector(
                          onTap: () => setState(() {
                            _hasNeverDonated = !_hasNeverDonated;
                            if (_hasNeverDonated) _lastDonationDate = null;
                          }),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _hasNeverDonated
                                      ? const Color(0xFFB71C1C)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: _hasNeverDonated
                                        ? const Color(0xFFB71C1C)
                                        : const Color(0xFFBDBDBD),
                                  ),
                                ),
                                child: _hasNeverDonated
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 14)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              // ✅ TRANSLATED
                              Text(l10n.neverDonatedBefore,
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF1A1A1A))),
                            ],
                          ),
                        ),

                        if (!_hasNeverDonated) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _pickLastDonationDate,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _lastDonationDate == null
                                      ? const Color(0xFFBDBDBD)
                                      : const Color(0xFFB71C1C),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      color: Color(0xFFB71C1C), size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    _lastDonationDate == null
                                        // ✅ TRANSLATED
                                        ? l10n.selectDate
                                        : '${_lastDonationDate!.day}/${_lastDonationDate!.month}/${_lastDonationDate!.year}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _lastDonationDate == null
                                          ? const Color(0xFFBDBDBD)
                                          : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_drop_down,
                                      color: Color(0xFFBDBDBD)),
                                ],
                              ),
                            ),
                          ),
                          if (_lastDonationDate != null) ...[
                            const SizedBox(height: 8),
                            Builder(builder: (context) {
                              final threeMonthsAgo = DateTime.now()
                                  .subtract(const Duration(days: 90));
                              final isTooRecent =
                                  _lastDonationDate!.isAfter(threeMonthsAgo);
                              return isTooRecent
                                  ? Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.warning_outlined,
                                              color: Color(0xFFB71C1C),
                                              size: 16),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            // ✅ TRANSLATED
                                            child: Text(
                                              '❌ ${l10n.notEligibleDonation}',
                                              style: const TextStyle(
                                                  color: Color(0xFFB71C1C),
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline,
                                              color: Colors.green, size: 16),
                                          const SizedBox(width: 6),
                                          // ✅ TRANSLATED
                                          Text(
                                            '✅ ${l10n.youAreEligible}',
                                            style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    );
                            }),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ✅ TRANSLATED Password
                _buildField(
                  controller: _passwordController,
                  hint: l10n.password,
                  icon: Icons.lock_outline,
                  obscure: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 14),

                // ✅ TRANSLATED Confirm password
                _buildField(
                  controller: _confirmController,
                  hint: l10n.confirmPassword,
                  icon: Icons.lock_outline,
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) => v != _passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        // ✅ TRANSLATED
                        : Text(l10n.createAccount,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text.rich(
                      TextSpan(
                        // ✅ TRANSLATED
                        text: '${l10n.alreadyHaveAccount} ',
                        style: const TextStyle(
                            color: Color(0xFF9E9E9E), fontSize: 14),
                        children: [
                          TextSpan(
                            text: l10n.login,
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint: hint, icon: icon).copyWith(
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFFBDBDBD),
                ),
                onPressed: onToggle,
              )
            : null,
      ),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Icon(icon, color: const Color(0xFFBDBDBD)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1.5)),
    );
  }
}
