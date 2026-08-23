import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pixel_ui.dart';

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  bool _isNewStudent = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(authProvider.notifier).login(
          classCode: _classCodeController.text.trim(),
          username: _usernameController.text.trim(),
          name: _isNewStudent ? _nameController.text.trim() : null,
          password: _passwordController.text,
        );

    if (result['success'] == true && mounted) {
      final student = ref.read(authProvider).student;
      if (student?.mustChangePassword == true) {
        context.go('/change-password');
      } else {
        context.go('/character-selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: PixelBackdrop(
        baseColor: AppColors.background,
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
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: AppColors.accent,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_stories,
                                size: 44,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'CHRONOQUEST',
                              style: GoogleFonts.pressStart2p(
                                fontSize: 22,
                                height: 1.4,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tuklasin ang Kasaysayan\nng Pilipinas',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.pixelifySans(
                                fontSize: 17,
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
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.primaryDark, width: 3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark,
                            offset: Offset(5, 5),
                            blurRadius: 0,
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
                                border: Border.all(
                                    color: AppColors.primaryDark, width: 2),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _isNewStudent = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        color: _isNewStudent
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Bago',
                                          style: GoogleFonts.pixelifySans(
                                            color: _isNewStudent
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _isNewStudent = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        color: !_isNewStudent
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Babalik',
                                          style: GoogleFonts.pixelifySans(
                                            color: !_isNewStudent
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
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
                              decoration:
                                  _inputDeco(Icons.class_, 'e.g. CQ-G5A1'),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Kailangan ang class code'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _buildLabel('Username'),
                            TextFormField(
                              controller: _usernameController,
                              decoration: _inputDeco(
                                  Icons.alternate_email, 'e.g. JuanNinja99'),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Kailangan ang username'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            if (_isNewStudent) ...[
                              _buildLabel('Tunay na Pangalan'),
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: _inputDeco(Icons.person,
                                    'Buong pangalan para kay titser'),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Kailangan ang tunay na pangalan'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                            ],
                            _buildLabel('Password'),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration:
                                  _inputDeco(Icons.lock, 'Lagyan ng password')
                                      .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Kailangan ang password';
                                if (v.length < 6)
                                  return 'Hindi bababa sa 6 na characters';
                                return null;
                              },
                            ),
                            if (_isNewStudent) ...[
                              const SizedBox(height: 12),
                              _buildLabel('Kumpirmahin ang Password'),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirm,
                                decoration: _inputDeco(Icons.lock_outline,
                                        'Ulitin ang password')
                                    .copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: AppColors.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Kailangan kumpirmahin ang password';
                                  if (v != _passwordController.text)
                                    return 'Hindi magkatugma ang password';
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 8),
                            if (authState.error != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 4),
                                child: Text(
                                  authState.error!,
                                  style: const TextStyle(
                                      color: AppColors.danger, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 16),
                            authState.isLoading
                                ? const SizedBox(
                                    height: 52,
                                    child: Center(
                                      child: SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                  )
                                : PixelButton(
                                    label: _isNewStudent
                                        ? 'SUMALI SA KLASE'
                                        : 'MAG-LOGIN',
                                    fontSize: 11,
                                    width: double.infinity,
                                    onPressed: _login,
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
        style: GoogleFonts.pixelifySans(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
      ),
    );
  }

  InputDecoration _inputDeco(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.pixelifySans(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      filled: true,
      fillColor: AppColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.accent, width: 3),
      ),
      errorStyle: const TextStyle(height: 0.8),
    );
  }
}
