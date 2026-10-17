import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/game_ui.dart';
import 'auth_widgets.dart';

/// Saves the new password on the server, then remembers on the phone that it was
/// changed. Throws a message that is ready to show.
Future<void> saveNewPassword(String password) async {
  await ApiService().changePassword(password);
  final student = StorageService.getStudent();
  if (student != null) {
    student.mustChangePassword = false;
    await StorageService.saveStudent(student);
  }
}

/// Shown after a first login with a password the teacher made. Two big boxes, a
/// line that turns green as the password becomes good enough, and the same guide
/// as the sign-in screen. There is no way back: it is required.
class ChangePasswordScreen extends StatefulWidget {
  /// Tests pass a fake; the app saves to the server.
  final Future<void> Function(String newPassword) save;

  const ChangePasswordScreen({super.key, this.save = saveNewPassword});

  static const newKey = ValueKey('change_new');
  static const confirmKey = ValueKey('change_confirm');
  static const saveKey = ValueKey('change_save');

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _longEnough => _new.text.length >= 6;
  bool get _matches => _confirm.text.isNotEmpty && _confirm.text == _new.text;
  bool get _ready => _longEnough && _matches;

  void _typed() => setState(() => _error = null);

  Future<void> _submit() async {
    if (!_ready || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.save(_new.text);
      if (mounted) context.go('/character-selection');
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is String ? e : 'Hindi ma-save ang password. Subukan ulit.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 560;
    final say = _error != null
        ? 'Hindi pa na-save. Subukan ulit.'
        : _ready
            ? 'Ayos! Handa ka na.'
            : _new.text.isNotEmpty && _confirm.text.isNotEmpty && !_matches
                ? 'Halos tama na! Dapat pareho ang dalawa.'
                : 'Gumawa ng sarili mong password. Ikaw lang ang dapat makaalam.';

    final form = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('BAGONG PASSWORD', gold: true),
        const SizedBox(height: 5),
        AuthField(
          key: ChangePasswordScreen.newKey,
          controller: _new,
          hint: '6 o higit pa',
          password: true,
          autofocus: true,
          height: 52,
          state: _new.text.isNotEmpty && _longEnough
              ? AuthFieldState.ok
              : AuthFieldState.normal,
          onChanged: (_) => _typed(),
        ),
        const SizedBox(height: 14),
        _label('ULITIN ANG PASSWORD'),
        const SizedBox(height: 5),
        AuthField(
          key: ChangePasswordScreen.confirmKey,
          controller: _confirm,
          hint: 'Ulitin ang password',
          password: true,
          height: 52,
          action: TextInputAction.done,
          state: _confirm.text.isEmpty
              ? AuthFieldState.normal
              : _matches
                  ? AuthFieldState.ok
                  : AuthFieldState.bad,
          onChanged: (_) => _typed(),
          onSubmitted: _submit,
        ),
        const SizedBox(height: 10),
        if (_error != null)
          AuthError(_error!)
        else if (_ready)
          const AuthHelp('✓ 6 o higit pang character   ✓ Pareho na', good: true)
        else if (_confirm.text.isNotEmpty && !_matches && _longEnough)
          const AuthHelp('Hindi pareho ang dalawa.', good: false)
        else
          AuthHelp(_longEnough
              ? '✓ 6 o higit pang character'
              : 'Kailangan mo ito bago maglaro. 6 o higit pang character.'),
        const SizedBox(height: 12),
        _loading
            ? const AuthBusyButton(label: 'SINASAVE…')
            : GameButton(
                key: ChangePasswordScreen.saveKey,
                label: 'I-SAVE AT TULOY',
                fontSize: 13,
                width: double.infinity,
                onPressed: _ready ? _submit : null,
              ),
      ],
    );

    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: wide
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 236,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AuthWordmark(),
                              const SizedBox(height: 12),
                              AuthGuide(say: say, fontSize: 14),
                            ],
                          ),
                        ),
                        const SizedBox(width: 28),
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: form,
                          ),
                        ),
                      ],
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            say,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                              color: AppColors.surface,
                            ),
                          ),
                          const SizedBox(height: 14),
                          form,
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {bool gold = false}) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: gold ? 14 : 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: gold ? AppColors.accent : authSoftText,
        ),
      );
}
