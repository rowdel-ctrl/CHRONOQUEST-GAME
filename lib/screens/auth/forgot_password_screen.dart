import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../services/api_service.dart';
import '../../utils/login_errors.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';
import 'auth_widgets.dart';

/// What this screen needs from the sign-in screen: the class code and username
/// the student already typed.
class ForgotPasswordArgs {
  final String classCode;
  final String username;
  const ForgotPasswordArgs({required this.classCode, required this.username});
}

/// Sends the request to the teacher. Throws a message that is ready to show.
Future<void> sendResetRequest(String classCode, String username) =>
    ApiService().requestPasswordReset(classCode: classCode, username: username);

enum _Phase { ask, sending, sent }

/// "Forgot password?" on the sign-in screen leads here. The student sees the
/// class code and username to read out to the teacher, and one button sends the
/// teacher a request (it shows up in the teacher's dashboard, where the teacher
/// makes a temporary password). If the request cannot be sent, the message says to
/// tell the teacher in person, which the boxes already make easy.
class ForgotPasswordScreen extends StatefulWidget {
  final String classCode;
  final String username;

  /// Tests pass a fake; the app asks the server.
  final Future<void> Function(String classCode, String username) send;

  const ForgotPasswordScreen({
    super.key,
    required this.classCode,
    required this.username,
    this.send = sendResetRequest,
  });

  static const backKey = ValueKey('forgot_back');
  static const sendKey = ValueKey('forgot_send');
  static const haveKey = ValueKey('forgot_have');
  static const doneKey = ValueKey('forgot_done');

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _Phase _phase = _Phase.ask;
  String? _error;

  Future<void> _send() async {
    if (_phase == _Phase.sending) return;
    setState(() {
      _phase = _Phase.sending;
      _error = null;
    });
    try {
      await widget.send(widget.classCode, widget.username);
      if (mounted) setState(() => _phase = _Phase.sent);
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.ask;
          _error = e is String ? e : resetRequestCannotSend;
        });
      }
    }
  }

  /// Back to the sign-in screen it was opened from.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 560;
    final say = switch (_phase) {
      _Phase.sent => 'Na-send na! Hintayin ang teacher mo.',
      _Phase.sending => 'Sandali lang, sending…',
      _Phase.ask => _error != null
          ? 'Hindi na-send. Subukan ulit.'
          : 'Okay lang! Hihingi tayo ng reset sa teacher mo.',
    };
    final form = _phase == _Phase.sent ? _sentForm() : _askForm();

    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 8,
                top: 4,
                child: MenuChip(
                  key: ForgotPasswordScreen.backKey,
                  icon: PixelGlyph.back,
                  tooltip: 'Bumalik',
                  onTap: _leave,
                ),
              ),
              Positioned.fill(
                top: 44,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
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
                                    const SizedBox(height: 10),
                                    AuthGuide(say: say, fontSize: 14, sprite: 96),
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
            ],
          ),
        ),
      ),
    );
  }

  /// The class code and username to read out, then the two buttons.
  Widget _askForm() {
    final sending = _phase == _Phase.sending;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'I-send ito sa teacher mo:',
          style: GoogleFonts.poppins(
            fontSize: 19,
            height: 1.25,
            fontWeight: FontWeight.bold,
            color: AppColors.surface,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            final code = AuthReadout(label: 'CLASS CODE', value: widget.classCode);
            final user = AuthReadout(label: 'USERNAME', value: widget.username);
            if (box.maxWidth >= 380) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: code),
                  const SizedBox(width: 12),
                  Expanded(child: user),
                ],
              );
            }
            return Column(children: [code, const SizedBox(height: 10), user]);
          },
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[AuthError(_error!), const SizedBox(height: 12)],
        sending
            ? const AuthBusyButton(label: 'SENDING…')
            : GameButton(
                key: ForgotPasswordScreen.sendKey,
                label: 'I-SEND SA TEACHER',
                fontSize: 13,
                width: double.infinity,
                onPressed: _send,
              ),
        const SizedBox(height: 12),
        GameButton(
          key: ForgotPasswordScreen.haveKey,
          label: 'MAY PASSWORD NA AKO',
          fontSize: 12,
          minHeight: 44,
          width: double.infinity,
          color: AppColors.primary,
          textColor: AppColors.surface,
          onPressed: sending ? null : _leave,
        ),
      ],
    );
  }

  /// After the request is sent.
  Widget _sentForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 36),
            const SizedBox(width: 10),
            Text(
              'Na-send na!',
              style: GoogleFonts.poppins(
                fontSize: 23,
                height: 1.25,
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const AuthHelp(
          'Makikita ito ng teacher mo. Pwede kang bumalik mamaya. '
          'Hindi mo kailangang maghintay dito.',
        ),
        const SizedBox(height: 16),
        GameButton(
          key: ForgotPasswordScreen.doneKey,
          label: 'BUMALIK SA LOGIN',
          fontSize: 13,
          width: double.infinity,
          onPressed: _leave,
        ),
      ],
    );
  }
}
