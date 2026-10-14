import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../utils/login_errors.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';
import '../../widgets/qr_scan_panel.dart';
import 'auth_widgets.dart';

/// One question at a time, in this order.
enum LoginStep { classCode, name, username, password, confirm }

/// Sign in and sign up. The student first picks "Bago ako" or "Balik na ako",
/// then answers one question per screen. The QR scan card is on the left of the
/// class code question only; on the other questions the guide takes its place.
class LoginScreen extends ConsumerStatefulWidget {
  /// The camera view for QR scanning. Tests pass a fake; the app uses the camera.
  final ScannerViewBuilder scannerBuilder;

  const LoginScreen({super.key, this.scannerBuilder = cameraScannerView});

  static const newKey = ValueKey('login_new');
  static const returningKey = ValueKey('login_returning');
  static const nextKey = ValueKey('login_next');
  static const backKey = ValueKey('login_back');
  static const stepsKey = ValueKey('login_steps');

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _classCode = TextEditingController();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  /// null: still on the first screen, choosing. true: "Bago ako". false: "Balik na ako".
  bool? _joining;
  int _index = 0;

  /// The class code a QR scan filled in. The box stays editable: it shows the
  /// green "scanned" look only while it still holds exactly this.
  String? _scannedCode;

  /// A problem found on the phone (an empty box), and the question it belongs to.
  String? _localError;
  LoginStep? _localErrorAt;

  /// The question the server's complaint is about.
  LoginStep? _serverErrorAt;

  @override
  void dispose() {
    _classCode.dispose();
    _name.dispose();
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  List<LoginStep> get _steps => _joining == true
      ? LoginStep.values
      : const [LoginStep.classCode, LoginStep.username, LoginStep.password];

  LoginStep get _step => _steps[_index];

  bool get _isLast => _index == _steps.length - 1;

  bool get _codeIsScanned =>
      _scannedCode != null && _classCode.text.trim() == _scannedCode;

  TextEditingController _controllerFor(LoginStep s) => switch (s) {
        LoginStep.classCode => _classCode,
        LoginStep.name => _name,
        LoginStep.username => _username,
        LoginStep.password => _password,
        LoginStep.confirm => _confirm,
      };

  /// An error belongs to what was typed when it came back; once the student
  /// changes any box it is stale.
  void _clearErrors() {
    ref.read(authProvider.notifier).clearError();
    _localError = null;
    _localErrorAt = null;
  }

  void _choose(bool joining) {
    _clearErrors();
    setState(() {
      _joining = joining;
      _index = 0;
    });
  }

  void _back() {
    _clearErrors();
    setState(() {
      if (_index > 0) {
        _index--;
      } else {
        _joining = null;
      }
    });
  }

  void _applyScannedCode(String code) {
    _clearErrors();
    setState(() => _scannedCode = code);
    _classCode.text = code;
  }

  Future<void> _scanFromSheet() async {
    final code = await showQrScanSheet(context, scannerBuilder: widget.scannerBuilder);
    if (code != null && mounted) _applyScannedCode(code);
  }

  /// What is wrong with the answer to [s], or null when it will do.
  String? _check(LoginStep s) {
    final text = _controllerFor(s).text;
    switch (s) {
      case LoginStep.classCode:
        return text.trim().isEmpty ? 'Kailangan ang class code' : null;
      case LoginStep.name:
        return text.trim().isEmpty ? 'Kailangan ang tunay na pangalan' : null;
      case LoginStep.username:
        return text.trim().isEmpty ? 'Kailangan ang username' : null;
      case LoginStep.password:
        if (text.isEmpty) return 'Kailangan ang password';
        // The length rule is for choosing a password. On "Balik na ako" a short
        // one is just a wrong one, and the server says so.
        if (_joining == true && text.length < 6) return 'Hindi bababa sa 6 na characters';
        return null;
      case LoginStep.confirm:
        if (text.isEmpty) return 'Kailangan kumpirmahin ang password';
        if (text != _password.text) return 'Hindi magkatugma ang password';
        return null;
    }
  }

  void _next() {
    final problem = _check(_step);
    if (problem != null) {
      setState(() {
        _localError = problem;
        _localErrorAt = _step;
      });
      return;
    }
    _clearErrors();
    if (_isLast) {
      _submit();
    } else {
      setState(() => _index++);
    }
  }

  Future<void> _submit() async {
    final result = await ref.read(authProvider.notifier).login(
          classCode: _classCode.text.trim(),
          username: _username.text.trim(),
          name: _joining == true ? _name.text.trim() : null,
          password: _password.text,
        );
    if (!mounted) return;

    if (result['success'] == true) {
      final student = ref.read(authProvider).student;
      context.go(student?.mustChangePassword == true
          ? '/change-password'
          : '/character-selection');
      return;
    }

    // Go back to the question the problem is about, with what was typed kept.
    // A problem that is about none of them (no internet) stays on the last one.
    final message = ref.read(authProvider).error;
    final field = message == null ? null : loginErrorField(message);
    final at = switch (field) {
      LoginField.classCode => LoginStep.classCode,
      LoginField.name => LoginStep.name,
      LoginField.username => LoginStep.username,
      LoginField.password => LoginStep.password,
      null => null,
    };
    setState(() {
      final target = at != null && _steps.contains(at) ? at : _steps.last;
      _serverErrorAt = target;
      _index = _steps.indexOf(target);
    });
  }

  String? _errorFor(LoginStep s, AuthState auth) {
    if (_localErrorAt == s) return _localError;
    if (auth.error != null && (_serverErrorAt ?? _steps.last) == s) return auth.error;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final size = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: _joining == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: GameBackdrop(
          baseColor: AppColors.background,
          child: SafeArea(
            child: _joining == null
                ? _ChoiceView(width: size.width, onChoose: _choose)
                : _stepsView(auth, size.width > 700),
          ),
        ),
      ),
    );
  }

  Widget _stepsView(AuthState auth, bool wide) {
    final step = _step;
    final error = _errorFor(step, auth);
    final mode = _joining == true ? 'Bago ako' : 'Balik na ako';
    return Stack(
      children: [
        Positioned(
          left: 8,
          top: 4,
          child: MenuChip(
            key: LoginScreen.backKey,
            icon: PixelGlyph.back,
            tooltip: 'Bumalik',
            onTap: _back,
          ),
        ),
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: AuthStepBar(
              key: LoginScreen.stepsKey,
              count: _steps.length,
              index: _index,
              caption: '$mode · Hakbang ${_index + 1} ng ${_steps.length}',
            ),
          ),
        ),
        Positioned.fill(
          top: 64,
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight - 20),
                child: Center(
                  child: wide
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(width: 262, child: _leftColumn(auth, error)),
                            const SizedBox(width: 28),
                            Flexible(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 480),
                                child: _question(auth, error, wide: true),
                              ),
                            ),
                          ],
                        )
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _question(auth, error, wide: false),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The scan card on the class code question, the guide on all the others.
  Widget _leftColumn(AuthState auth, String? error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AuthWordmark(),
        const SizedBox(height: 10),
        if (_step == LoginStep.classCode)
          QrScanPanel(
            onCode: _applyScannedCode,
            scannerBuilder: widget.scannerBuilder,
          )
        else
          AuthGuide(
            say: auth.isLoading
                ? 'Sandali lang, sinusuri ko…'
                : error != null
                    ? 'May kailangang ayusin. Subukan ulit!'
                    : _guideLine(_step),
          ),
      ],
    );
  }

  String _guideLine(LoginStep s) => switch (s) {
        LoginStep.classCode => 'Nasa poster ni titser, o i-scan ang QR sa kaliwa.',
        LoginStep.name => 'Para makilala ka ni titser.',
        LoginStep.username => _joining == true
            ? 'Ito ang gagamitin mo sa pag-login.'
            : 'Kumusta ulit!',
        LoginStep.password => _joining == true
            ? 'Sikreto mo ito, ha!'
            : 'Maligayang pagbabalik!',
        LoginStep.confirm => 'Konti na lang!',
      };

  String _questionText(LoginStep s) => switch (s) {
        LoginStep.classCode => 'Anong class code ng klase mo?',
        LoginStep.name => 'Ano ang tunay mong pangalan?',
        LoginStep.username =>
          _joining == true ? 'Gumawa ng username mo.' : 'Ano ang username mo?',
        LoginStep.password =>
          _joining == true ? 'Gumawa ng password.' : 'Ano ang password mo?',
        LoginStep.confirm => 'Ulitin ang password.',
      };

  String _hint(LoginStep s) => switch (s) {
        LoginStep.classCode => 'EDG5A1',
        LoginStep.name => 'Buong pangalan',
        LoginStep.username => 'JuanNinja99',
        LoginStep.password => _joining == true ? 'Hindi bababa sa 6' : 'Password',
        LoginStep.confirm => 'Ulitin ang password',
      };

  Widget _question(AuthState auth, String? error, {required bool wide}) {
    final step = _step;
    final controller = _controllerFor(step);

    final AuthFieldState state;
    if (error != null) {
      state = AuthFieldState.bad;
    } else if ((step == LoginStep.classCode && _codeIsScanned) ||
        (step == LoginStep.confirm &&
            controller.text.isNotEmpty &&
            controller.text == _password.text)) {
      state = AuthFieldState.ok;
    } else {
      state = AuthFieldState.normal;
    }

    Widget? trailing;
    if (step == LoginStep.classCode) {
      if (_codeIsScanned) {
        trailing = const AuthTick();
      } else if (!wide) {
        trailing = IconButton(
          tooltip: 'I-scan ang QR',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 26),
          onPressed: _scanFromSheet,
        );
      }
    }

    // Under the box: the rule that ticks green as it is met, or a hint where the
    // guide is not on screen to say it.
    Widget? help;
    if (error != null) {
      help = AuthError(error);
    } else if (_joining == true && step == LoginStep.password) {
      help = AuthHelp(
        controller.text.length >= 6
            ? '✓ 6 o higit pang character'
            : 'Hindi bababa sa 6 na character',
        good: controller.text.length >= 6 ? true : null,
      );
    } else if (step == LoginStep.confirm && controller.text.isNotEmpty) {
      final match = controller.text == _password.text;
      help = AuthHelp(match ? '✓ Magkatugma' : 'Hindi pa magkatugma', good: match);
    } else if (step == LoginStep.classCode && _codeIsScanned) {
      help = const AuthHelp('Na-scan mula sa QR ni titser.', good: true);
    } else if (step == LoginStep.classCode) {
      help = AuthHelp(wide
          ? 'Nasa poster ni titser, o i-scan ang QR sa kaliwa.'
          : 'Nasa poster ni titser, o pindutin ang scan.');
    } else if (!wide) {
      help = AuthHelp(_guideLine(step));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _questionText(step),
          style: GoogleFonts.poppins(
            fontSize: wide ? 23 : 19,
            height: 1.25,
            fontWeight: FontWeight.bold,
            color: AppColors.surface,
          ),
        ),
        const SizedBox(height: 12),
        AuthField(
          // A new box for each question, so the keyboard is up and the cursor in it.
          key: ValueKey(('answer', step)),
          controller: controller,
          hint: _hint(step),
          state: state,
          autofocus: true,
          password: step == LoginStep.password || step == LoginStep.confirm,
          capitalization: switch (step) {
            LoginStep.classCode => TextCapitalization.characters,
            LoginStep.name => TextCapitalization.words,
            _ => TextCapitalization.none,
          },
          action: _isLast ? TextInputAction.done : TextInputAction.next,
          trailing: trailing,
          onChanged: (_) {
            _clearErrors();
            setState(() {});
          },
          onSubmitted: _next,
        ),
        const SizedBox(height: 12),
        if (help != null) ...[help, const SizedBox(height: 12)],
        auth.isLoading
            ? const AuthBusyButton(label: 'SANDALI LANG…')
            : GameButton(
                key: LoginScreen.nextKey,
                label: _isLast
                    ? (_joining == true ? 'SUMALI SA KLASE' : 'MAG-LOGIN')
                    : 'SUSUNOD',
                fontSize: 13,
                width: double.infinity,
                onPressed: _next,
              ),
      ],
    );
  }
}

/// The first screen: the name, the guide, and two big buttons.
class _ChoiceView extends StatelessWidget {
  final double width;
  final ValueChanged<bool> onChoose;
  const _ChoiceView({required this.width, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    final row = width >= 560;
    final title = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'CHRONOQUEST',
            style: GoogleFonts.poppins(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              color: AppColors.accent,
              shadows: const [Shadow(color: AppColors.primaryDark, offset: Offset(0, 4))],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Image.asset(
          'assets/characters/luna_walk_1.png',
          width: row ? 132 : 84,
          height: row ? 132 : 84,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, __, ___) => const SizedBox(width: 84, height: 84),
        ),
      ],
    );
    final choices = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChoiceButton(
          key: LoginScreen.newKey,
          title: 'BAGO AKO',
          subtitle: 'Sasali ako sa klase ni titser',
          color: AppColors.accent,
          onTap: () => onChoose(true),
        ),
        const SizedBox(height: 16),
        _ChoiceButton(
          key: LoginScreen.returningKey,
          title: 'BALIK NA AKO',
          subtitle: 'May account na ako',
          color: AppColors.surface,
          onTap: () => onChoose(false),
        ),
      ],
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: row
            ? Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(child: title),
                  const SizedBox(width: 36),
                  SizedBox(width: 330, child: choices),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [title, const SizedBox(height: 20), choices],
              ),
      ),
    );
  }
}

class _ChoiceButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ChoiceButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<_ChoiceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.subtitle}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(0, _pressed ? 5 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primaryDark, width: 3),
            boxShadow: _pressed
                ? null
                : const [BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 21,
                  height: 1.25,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                widget.subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
