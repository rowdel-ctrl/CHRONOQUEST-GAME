import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _classCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  
  bool _isNewStudent = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _classCodeController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _pinController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(authProvider.notifier).login(
          classCode: _classCodeController.text.trim(),
          username: _usernameController.text.trim(),
          name: _isNewStudent ? _nameController.text.trim() : null,
          pin: !_isNewStudent ? _pinController.text.trim() : null,
        );

    if (result['success'] == true && mounted) {
      final pin = result['pin'];
      if (pin != null) {
        _showPinDialog(pin);
      } else {
        context.go('/character-selection');
      }
    }
  }

  void _showPinDialog(String pin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            'Ito ang iyong PIN!',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Isulat at tandaan ang 4-digit PIN na ito. Gagamitin mo ito sa pag-login muli!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Text(
                pin,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/character-selection');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('NAISULAT KO NA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0E0A),
              Color(0xFF3E2723),
              Color(0xFF5D4037),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (screenSize.width > 700) ...[
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: AppColors.accent.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_stories,
                                size: 48,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'ChronoQuest',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tuklasin ang Kasaysayan\nng Pilipinas',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.sourceSans3(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],

                    Container(
                      width: screenSize.width > 700 ? 380 : 340,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isNewStudent = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _isNewStudent ? AppColors.primary : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Bago',
                                          style: TextStyle(
                                            color: _isNewStudent ? Colors.white : AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isNewStudent = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: !_isNewStudent ? AppColors.primary : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Babalik',
                                          style: TextStyle(
                                            color: !_isNewStudent ? Colors.white : AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            _buildLabel('Class Code'),
                            TextFormField(
                              controller: _classCodeController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: _inputDeco(Icons.class_, 'e.g. CQ-G5A1'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Kailangan ang class code' : null,
                            ),
                            const SizedBox(height: 12),

                            _buildLabel('Username'),
                            TextFormField(
                              controller: _usernameController,
                              decoration: _inputDeco(Icons.alternate_email, 'e.g. JuanNinja99'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Kailangan ang username' : null,
                            ),
                            const SizedBox(height: 12),

                            if (_isNewStudent) ...[
                              _buildLabel('Tunay na Pangalan'),
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: _inputDeco(Icons.person, 'Buong pangalan para kay titser'),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Kailangan ang tunay na pangalan' : null,
                              ),
                            ] else ...[
                              _buildLabel('4-Digit PIN'),
                              TextFormField(
                                controller: _pinController,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                obscureText: true,
                                decoration: _inputDeco(Icons.lock, 'XXXX').copyWith(counterText: ''),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Kailangan ang PIN' : null,
                              ),
                            ],
                            const SizedBox(height: 8),

                            if (authState.error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 4),
                                child: Text(
                                  authState.error!,
                                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            const SizedBox(height: 16),

                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: authState.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        height: 20, width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        _isNewStudent ? 'SUMALI SA KLASE' : 'MAG-LOGIN',
                                        style: GoogleFonts.sourceSans3(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.sourceSans3(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
      ),
    );
  }

  InputDecoration _inputDeco(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      filled: true,
      fillColor: AppColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorStyle: const TextStyle(height: 0.8),
    );
  }
}