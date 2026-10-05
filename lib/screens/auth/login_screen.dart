import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/qr_scan_panel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  /// The camera view for QR scanning. Tests pass a fake; the app uses the camera.
  final ScannerViewBuilder scannerBuilder;

  const LoginScreen({super.key, this.scannerBuilder = cameraScannerView});

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

  /// The class code a QR scan filled in. The field stays editable: it shows the
  /// green "scanned" look only while it still holds exactly this.
  String? _scannedCode;

  @override
  void initState() {
    super.initState();
    _classCodeController.addListener(() {
      if (_scannedCode != null && mounted) setState(() {});
    });
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

  void _applyScannedCode(String code) {
    setState(() => _scannedCode = code);
    _classCodeController.text = code;
  }

  Future<void> _scanFromSheet() async {
    final code = await showQrScanSheet(context, scannerBuilder: widget.scannerBuilder);
    if (code != null && mounted) _applyScannedCode(code);
  }

  bool get _codeIsScanned =>
      _scannedCode != null && _classCodeController.text.trim() == _scannedCode;

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
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // Top-aligned: the form is taller than a landscape phone, and
                  // centred the scan card slid below the first screen.
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (screenSize.width > 700) ...[
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Small wordmark: the logo block gave way to the
                            // scanner, but the name stays.
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_stories,
                                      size: 18, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CHRONOQUEST',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            QrScanPanel(
                              onCode: _applyScannedCode,
                              scannerBuilder: widget.scannerBuilder,
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
                                          style: GoogleFonts.poppins(
                                            color: _isNewStudent
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
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
                                          style: GoogleFonts.poppins(
                                            color: !_isNewStudent
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
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
                                  _inputDeco(Icons.class_, 'e.g. EDG5A1')
                                      .copyWith(
                                enabledBorder: _codeIsScanned
                                    ? OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: const BorderSide(
                                            color: AppColors.success, width: 3),
                                      )
                                    : null,
                                suffixIcon: _codeIsScanned
                                    ? const Icon(Icons.check_circle,
                                        color: AppColors.success, size: 20)
                                    : screenSize.width > 700
                                        ? null
                                        : IconButton(
                                            tooltip: 'I-scan ang QR',
                                            icon: const Icon(
                                                Icons.qr_code_scanner,
                                                color: AppColors.primary),
                                            onPressed: _scanFromSheet,
                                          ),
                              ),
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
                                : GameButton(
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
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
    );
  }

  InputDecoration _inputDeco(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: AppColors.textMuted),
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
