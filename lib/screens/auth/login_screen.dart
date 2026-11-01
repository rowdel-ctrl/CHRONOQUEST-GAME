import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/server_clock.dart';
import '../../services/storage_service.dart';
import '../../utils/login_errors.dart';
import '../../utils/person_name.dart';
import '../../widgets/connection_corner.dart';
import '../../widgets/fact_ticker.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/guest_card.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';
import '../../widgets/qr_scan_panel.dart';
import '../../widgets/update_card.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';

/// The class code and username of the last sign-in on this phone.
typedef LastSignIn = ({String classCode, String username});

/// Reads them from the phone: null when there are none, or when storage is not
/// open (as in a widget test).
LastSignIn? rememberedSignIn() {
  try {
    return StorageService.getLastSignIn();
  } catch (_) {
    return null;
  }
}

/// One question at a time. "Bago ako" asks the class code, the first name, the
/// last name and the password twice; the username is made by the server from the
/// name. "Balik na ako" asks the class code, the username and the password.
enum LoginStep { classCode, firstName, lastName, username, password, confirm }

/// Sign in and sign up. The student first picks "Bago ako" or "Balik na ako",
/// then answers one question per screen. The QR scan card is on the left of the
/// class code question only; on the other questions the guide takes its place.
class LoginScreen extends ConsumerStatefulWidget {
  /// The camera view for QR scanning. Tests pass a fake; the app uses the camera.
  final ScannerViewBuilder scannerBuilder;

  /// Where "Balik na ako" finds the last sign-in. Tests pass a fake.
  final LastSignIn? Function() lastSignIn;

  /// Whether the game can reach its server, for the signal icon on the first
  /// screen. null: the game clock's reading. Tests pass their own.
  final ValueListenable<bool?>? connection;

  /// Asks for a fresh reading of [connection]. null: the game clock reads the
  /// server (at most once in 20 seconds, so staying on this screen is cheap).
  final VoidCallback? checkConnection;

  const LoginScreen({
    super.key,
    this.scannerBuilder = cameraScannerView,
    this.lastSignIn = rememberedSignIn,
    this.connection,
    this.checkConnection,
  });

  static const newKey = ValueKey('login_new');
  static const returningKey = ValueKey('login_returning');
  static const guestKey = ValueKey('login_guest');
  static const nextKey = ValueKey('login_next');
  static const backKey = ValueKey('login_back');
  static const stepsKey = ValueKey('login_steps');
  static const forgotKey = ValueKey('login_forgot');
  static const identityKey = ValueKey('login_identity');
  static const changeKey = ValueKey('login_change');
  static const sameNameLoginKey = ValueKey('login_same_name_login');
  static const sameNameGoOnKey = ValueKey('login_same_name_go_on');

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _classCode = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
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

  /// True while the password question shows who is signing in (the class code and
  /// username this phone remembered), with a way to change them.
  bool _identityShown = false;

  /// True while the screen asks "Ikaw ba 'yon?": a student with this name is
  /// already in the class.
  bool _nameTaken = false;

  @override
  void dispose() {
    _classCode.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  List<LoginStep> get _steps => _joining == true
      ? const [
          LoginStep.classCode,
          LoginStep.firstName,
          LoginStep.lastName,
          LoginStep.password,
          LoginStep.confirm,
        ]
      : const [LoginStep.classCode, LoginStep.username, LoginStep.password];

  LoginStep get _step => _steps[_index];

  bool get _isLast => _index == _steps.length - 1;

  bool get _codeIsScanned =>
      _scannedCode != null && _classCode.text.trim() == _scannedCode;

  TextEditingController _controllerFor(LoginStep s) => switch (s) {
        LoginStep.classCode => _classCode,
        LoginStep.firstName => _firstName,
        LoginStep.lastName => _lastName,
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

  /// "Play as a guest": asks once, then starts a guest session on the character
  /// screen. For demos; see [GuestMode].
  Future<void> _playAsGuest() async {
    if (!await showGuestConfirm(context) || !mounted) return;
    await ref.read(authProvider.notifier).startGuest();
    if (mounted) context.go('/character-selection');
  }

  void _choose(bool joining) {
    _clearErrors();
    // "Balik na ako" on a phone that remembers the last sign-in goes straight to the
    // password question. Not when the student has already typed something here.
    final last =
        joining || _classCode.text.isNotEmpty || _username.text.isNotEmpty
            ? null
            : widget.lastSignIn();
    setState(() {
      _joining = joining;
      _identityShown = last != null;
      if (last != null) {
        _classCode.text = last.classCode;
        _username.text = last.username;
        _index = _steps.indexOf(LoginStep.password);
      } else {
        _index = 0;
      }
    });
  }

  void _back() {
    _clearErrors();
    if (_nameTaken) {
      // Back to the last question, to change the name or the password.
      setState(() => _nameTaken = false);
      return;
    }
    setState(() {
      _identityShown = false;
      if (_index > 0) {
        _index--;
      } else {
        _joining = null;
      }
    });
  }

  /// "Hindi ikaw? Palitan": back to the first question, with the remembered
  /// answers in the boxes to change.
  void _changeIdentity() {
    _clearErrors();
    setState(() {
      _identityShown = false;
      _index = 0;
    });
  }

  /// "Forgot password?": to the screen that asks the teacher for a new one.
  void _forgot() {
    context.push(
      '/forgot-password',
      extra: ForgotPasswordArgs(
        classCode: _classCode.text.trim(),
        username: _username.text.trim(),
      ),
    );
  }

  void _applyScannedCode(String code) {
    _clearErrors();
    setState(() => _scannedCode = code);
    _classCode.text = code;
  }

  Future<void> _scanFromSheet() async {
    final code =
        await showQrScanSheet(context, scannerBuilder: widget.scannerBuilder);
    if (code != null && mounted) _applyScannedCode(code);
  }

  /// What is wrong with the answer to [s], or null when it will do.
  String? _check(LoginStep s) {
    final text = _controllerFor(s).text;
    switch (s) {
      case LoginStep.classCode:
        return text.trim().isEmpty ? 'I-type ang class code' : null;
      case LoginStep.firstName:
        return nameProblem(tidyName(text), NameBox.first);
      case LoginStep.lastName:
        return nameProblem(tidyName(text), NameBox.last) ??
            sameWordProblem(tidyName(_firstName.text), tidyName(text));
      case LoginStep.username:
        return text.trim().isEmpty ? 'I-type ang username' : null;
      case LoginStep.password:
        if (text.isEmpty) return 'I-type ang password';
        // The length rule is for choosing a password. On "Balik na ako" a short
        // one is just a wrong one, and the server says so.
        if (_joining == true && text.length < 6) {
          return 'Dapat 6 characters o higit pa';
        }
        return null;
      case LoginStep.confirm:
        if (text.isEmpty) return 'Ulitin ang password';
        if (text != _password.text) return 'Hindi pareho ang password';
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
    // Show the name the way it will be saved: "dela cruz" becomes "Dela Cruz".
    if (_step == LoginStep.firstName || _step == LoginStep.lastName) {
      final box = _controllerFor(_step);
      box.text = tidyName(box.text);
    }
    if (_isLast) {
      _submit();
    } else {
      setState(() => _index++);
    }
  }

  /// "Ikaw 'yon, mag-login": the name is taken by the student themselves, so this
  /// becomes a "Balik na ako" with the class code kept and the username to type.
  void _signInInstead() {
    _clearErrors();
    _username.clear();
    _password.clear();
    _confirm.clear();
    setState(() {
      _nameTaken = false;
      _joining = false;
      _identityShown = false;
      _index = _steps.indexOf(LoginStep.username);
    });
  }

  Future<void> _submit({bool allowSameName = false}) async {
    final joining = _joining == true;
    final result = await ref.read(authProvider.notifier).login(
          classCode: _classCode.text.trim(),
          // A new student has no username yet: the server makes it from the name.
          username: joining ? null : _username.text.trim(),
          name: joining
              ? fullName(tidyName(_firstName.text), tidyName(_lastName.text))
              : null,
          password: _password.text,
          allowSameName: allowSameName,
        );
    if (!mounted) return;

    if (result['success'] == true) {
      final student = ref.read(authProvider).student;
      // A new student gets a welcome, then sees the username the server made, once,
      // before the hero.
      if (result['isNewStudent'] == true) {
        context.go('/welcome');
        return;
      }
      context.go(student?.mustChangePassword == true
          ? '/change-password'
          : '/character-selection');
      return;
    }

    final message = ref.read(authProvider).error;
    if (message == nameTakenMessage) {
      ref.read(authProvider.notifier).clearError();
      setState(() => _nameTaken = true);
      return;
    }

    // Go back to the question the problem is about, with what was typed kept.
    // A problem that is about none of them (no internet) stays on the last one.
    final field = message == null ? null : loginErrorField(message);
    final at = switch (field) {
      LoginField.classCode => LoginStep.classCode,
      LoginField.name => LoginStep.firstName,
      LoginField.username => LoginStep.username,
      LoginField.password => LoginStep.password,
      null => null,
    };
    setState(() {
      _nameTaken = false;
      final target = at != null && _steps.contains(at) ? at : _steps.last;
      _serverErrorAt = target;
      _index = _steps.indexOf(target);
      // A problem with the class code or username means those are to be changed.
      if (target != LoginStep.password) _identityShown = false;
    });
  }

  String? _errorFor(LoginStep s, AuthState auth) {
    if (_localErrorAt == s) return _localError;
    if (auth.error != null && (_serverErrorAt ?? _steps.last) == s) {
      return auth.error;
    }
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
        body: Stack(
          children: [
            Positioned.fill(
              child: GameBackdrop(
                baseColor: AppColors.background,
                child: SafeArea(
                  child: _joining == null
                      ? _ChoiceView(
                          width: size.width,
                          onChoose: _choose,
                          onGuest: _playAsGuest,
                          connection:
                              widget.connection ?? ServerClock.instance.reachable,
                          checkConnection: widget.checkConnection ??
                              ServerClock.instance.syncIfNeeded,
                        )
                      : _stepsView(auth, size.width > 700),
                ),
              ),
            ),
            // The new-version card, over everything, when there is one: a phone
            // that is not signed in is told too.
            const Positioned.fill(child: UpdateCard()),
          ],
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
                            SizedBox(
                                width: 262, child: _leftColumn(auth, error)),
                            const SizedBox(width: 28),
                            Flexible(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 480),
                                child: _nameTaken
                                    ? _nameTakenView(auth, wide: true)
                                    : _question(auth, error, wide: true),
                              ),
                            ),
                          ],
                        )
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _nameTaken
                              ? _nameTakenView(auth, wide: false)
                              : _question(auth, error, wide: false),
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
                ? 'Sandali lang, chine-check ko…'
                : _nameTaken
                    ? 'Sandali lang!'
                    : error != null
                        ? 'May kailangang ayusin. Subukan ulit!'
                        : _guideLine(_step),
          ),
      ],
    );
  }

  String _guideLine(LoginStep s) => switch (s) {
        LoginStep.classCode =>
          'Nasa poster ng teacher mo, o i-scan ang QR sa kaliwa.',
        LoginStep.firstName =>
          'Tunay na pangalan, ha. Makikita ito ng teacher mo.',
        LoginStep.lastName => 'Konti na lang!',
        LoginStep.username => 'Kumusta ulit!',
        LoginStep.password =>
          _joining == true ? 'Sikreto mo ito, ha!' : 'Welcome back!',
        LoginStep.confirm => 'Last na!',
      };

  String _questionText(LoginStep s) => switch (s) {
        LoginStep.classCode => 'Anong class code ng klase mo?',
        LoginStep.firstName => 'Ano ang pangalan mo?',
        LoginStep.lastName => 'Ano ang apelyido mo?',
        LoginStep.username => 'Ano ang username mo?',
        LoginStep.password =>
          _joining == true ? 'Gumawa ng password.' : 'Ano ang password mo?',
        LoginStep.confirm => 'Ulitin ang password.',
      };

  String _hint(LoginStep s) => switch (s) {
        LoginStep.classCode => 'EDG5A1',
        LoginStep.firstName => 'Juan',
        LoginStep.lastName => 'Dela Cruz',
        LoginStep.username => 'juandelacruz',
        LoginStep.password => _joining == true ? '6 o higit pa' : 'Password',
        LoginStep.confirm => 'Ulitin ang password',
      };

  Widget _question(AuthState auth, String? error, {required bool wide}) {
    final step = _step;
    final controller = _controllerFor(step);

    // A last name that will do: the box turns green and shows the full name as the
    // teacher will see it.
    final lastNameOk = step == LoginStep.lastName &&
        nameProblem(tidyName(controller.text), NameBox.last) == null &&
        sameWordProblem(tidyName(_firstName.text), tidyName(controller.text)) ==
            null;

    final AuthFieldState state;
    if (error != null) {
      state = AuthFieldState.bad;
    } else if ((step == LoginStep.classCode && _codeIsScanned) ||
        lastNameOk ||
        (step == LoginStep.confirm &&
            controller.text.isNotEmpty &&
            controller.text == _password.text)) {
      state = AuthFieldState.ok;
    } else {
      state = AuthFieldState.normal;
    }

    Widget? trailing;
    if (lastNameOk) {
      trailing = const AuthTick();
    } else if (step == LoginStep.classCode) {
      if (_codeIsScanned) {
        trailing = const AuthTick();
      } else if (!wide) {
        trailing = IconButton(
          tooltip: 'I-scan ang QR',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          icon: const Icon(Icons.qr_code_scanner,
              color: AppColors.primary, size: 26),
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
            : 'Dapat 6 characters o higit pa',
        good: controller.text.length >= 6 ? true : null,
      );
    } else if (step == LoginStep.confirm && controller.text.isNotEmpty) {
      final match = controller.text == _password.text;
      help = AuthHelp(match ? '✓ Pareho na' : 'Hindi pa pareho', good: match);
    } else if (step == LoginStep.classCode && _codeIsScanned) {
      help = const AuthHelp('Na-scan mula sa QR ng teacher.', good: true);
    } else if (step == LoginStep.classCode) {
      help = AuthHelp(wide
          ? 'Nasa poster ng teacher mo, o i-scan ang QR sa kaliwa.'
          : 'Nasa poster ng teacher mo, o pindutin ang scan.');
    } else if (lastNameOk) {
      help = AuthHelp(
        '✓ Makikita ng teacher mo: ${fullName(tidyName(_firstName.text), tidyName(controller.text))}',
        good: true,
      );
    } else if (step == LoginStep.firstName) {
      help = const AuthHelp('Unang pangalan lang. Hal. Juan o Maria Clara.');
    } else if (step == LoginStep.lastName) {
      help = const AuthHelp('Apelyido lang. Hal. Dela Cruz.');
    } else if (step == LoginStep.username) {
      help = const AuthHelp(
          'Nasa isinulat o screenshot mo. Nakalimutan? Itanong sa teacher mo.');
    } else if (!wide) {
      help = AuthHelp(_guideLine(step));
    }

    // On "Balik na ako" the password question also says who is signing in, and has
    // the way out for a student who forgot the password.
    final returningPassword = _joining == false && step == LoginStep.password;
    final serverError = error != null && error == auth.error;
    final wrongPassword =
        serverError && loginErrorField(error) == LoginField.password;

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
        if (returningPassword && _identityShown) ...[
          _Identity(
            key: LoginScreen.identityKey,
            username: _username.text.trim(),
            classCode: _classCode.text.trim(),
            onChange: _changeIdentity,
          ),
          const SizedBox(height: 8),
        ],
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
            LoginStep.firstName ||
            LoginStep.lastName =>
              TextCapitalization.words,
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
        if (returningPassword) ...[
          _ForgotLink(
              key: LoginScreen.forgotKey, hot: wrongPassword, onTap: _forgot),
          const SizedBox(height: 12),
        ],
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

  /// "May Juan Dela Cruz na sa klase mo": the student is that person coming back
  /// (sign in instead), or another child with the same name (go on).
  Widget _nameTakenView(AuthState auth, {required bool wide}) {
    final name = fullName(tidyName(_firstName.text), tidyName(_lastName.text));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'May $name na sa klase mo.',
          style: GoogleFonts.poppins(
            fontSize: wide ? 23 : 19,
            height: 1.25,
            fontWeight: FontWeight.bold,
            color: AppColors.surface,
          ),
        ),
        const SizedBox(height: 12),
        const AuthHelp("Ikaw ba 'yon? Kung oo, mag-login ka na lang. "
            'Kung magkapangalan lang kayo, ituloy mo.'),
        const SizedBox(height: 14),
        GameButton(
          key: LoginScreen.sameNameLoginKey,
          label: "IKAW 'YON, MAG-LOGIN",
          fontSize: 13,
          width: double.infinity,
          onPressed: _signInInstead,
        ),
        const SizedBox(height: 14),
        auth.isLoading
            ? const AuthBusyButton(label: 'SANDALI LANG…')
            : GameButton(
                key: LoginScreen.sameNameGoOnKey,
                label: 'IBANG TAO AKO',
                fontSize: 13,
                width: double.infinity,
                color: AppColors.surface,
                onPressed: () => _submit(allowSameName: true),
              ),
      ],
    );
  }
}

/// Who is signing in, as the phone remembers it, and a way to change it.
class _Identity extends StatelessWidget {
  final String username;
  final String classCode;
  final VoidCallback onChange;
  const _Identity({
    super.key,
    required this.username,
    required this.classCode,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.account_circle, color: authSoftText, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$username · $classCode',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.surface,
            ),
          ),
        ),
        TextButton(
          key: LoginScreen.changeKey,
          onPressed: onChange,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Hindi ikaw? Palitan',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Forgot password?" under the password box. After a wrong password it becomes a
/// bordered button across the width, so a stuck student cannot miss it.
class _ForgotLink extends StatelessWidget {
  final bool hot;
  final VoidCallback onTap;
  const _ForgotLink({super.key, required this.hot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      hot ? 'Forgot password? Tap dito.' : 'Forgot password?',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: hot ? 14 : 13,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
        decoration: hot ? null : TextDecoration.underline,
        decorationColor: AppColors.accent,
      ),
    );
    // The whole row can be tapped, not only the words.
    return Semantics(
      button: true,
      label: 'Forgot password?',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          alignment: hot ? Alignment.center : Alignment.centerRight,
          padding: hot
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
              : const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: hot
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.accent, width: 2),
                )
              : null,
          child: text,
        ),
      ),
    );
  }
}

/// The first screen: the name, the guide, and two big buttons, on a backdrop that
/// is quietly alive (turning rays, fireflies, a hero that breathes), with an
/// "Alam mo ba?" line at the foot and the connection and version in the corners.
class _ChoiceView extends StatefulWidget {
  final double width;
  final ValueChanged<bool> onChoose;
  final VoidCallback onGuest;
  final ValueListenable<bool?> connection;
  final VoidCallback checkConnection;
  const _ChoiceView({
    required this.width,
    required this.onChoose,
    required this.onGuest,
    required this.connection,
    required this.checkConnection,
  });

  @override
  State<_ChoiceView> createState() => _ChoiceViewState();
}

class _ChoiceViewState extends State<_ChoiceView> {
  /// While the student sits on this screen the connection is read again now and
  /// then; the game clock itself keeps this to one read in twenty seconds.
  static const Duration recheckEvery = Duration(seconds: 20);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.checkConnection();
    _timer = Timer.periodic(recheckEvery, (_) => widget.checkConnection());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
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
              shadows: const [
                Shadow(color: AppColors.primaryDark, offset: Offset(0, 4))
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Bob(
          child: Image.asset(
            'assets/characters/luna_walk_1.png',
            width: row ? 132 : 84,
            height: row ? 132 : 84,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, __, ___) => const SizedBox(width: 84, height: 84),
          ),
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
          subtitle: 'Sasali ako sa klase ng teacher ko',
          color: AppColors.accent,
          onTap: () => widget.onChoose(true),
        ),
        const SizedBox(height: 16),
        _ChoiceButton(
          key: LoginScreen.returningKey,
          title: 'BALIK NA AKO',
          subtitle: 'May account na ako',
          color: AppColors.surface,
          onTap: () => widget.onChoose(false),
        ),
        const SizedBox(height: 14),
        _GuestButton(key: LoginScreen.guestKey, onTap: widget.onGuest),
      ],
    );
    return Stack(
      children: [
        // The light comes from behind the hero, wherever the hero is.
        Positioned.fill(
          child: LivingBackdrop(
            key: ChoiceKeys.backdrop,
            center: row ? const Offset(0.22, 0.58) : const Offset(0.5, 0.3),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            // Room at the foot for the "Alam mo ba?" line.
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
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
        ),
        Positioned(
          top: 8,
          right: 8,
          child: ConnectionCorner(status: widget.connection),
        ),
        // After "Later" on the new-version card, until it is installed.
        const Positioned(top: 4, left: 8, child: UpdateChip()),
        const Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Center(child: FactTicker(key: ChoiceKeys.fact)),
        ),
        const Positioned(right: 12, bottom: 6, child: VersionLabel()),
      ],
    );
  }
}

/// Keys the tests look the first screen's extras up by.
class ChoiceKeys {
  static const backdrop = ValueKey('choice_backdrop');
  static const fact = ValueKey('choice_fact');
}

/// The third choice, for demos: a slimmer wooden button, so it is easy to find
/// and still plainly not one of the two ways into a class.
class _GuestButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GuestButton({super.key, required this.onTap});

  @override
  State<_GuestButton> createState() => _GuestButtonState();
}

class _GuestButtonState extends State<_GuestButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play as a guest. Subukan muna ang laro',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primaryDark, width: 3),
            boxShadow: _pressed
                ? null
                : const [
                    BoxShadow(
                        color: AppColors.primaryDark, offset: Offset(0, 4))
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                  border: Border.all(color: AppColors.primaryDark, width: 2),
                ),
                child: const PixelIcon(PixelGlyph.profile,
                    size: 14, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PLAY AS A GUEST',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      'Subukan muna ang laro',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: AppColors.surface,
                      ),
                    ),
                  ],
                ),
              ),
              const PixelIcon(PixelGlyph.chevron,
                  size: 14, color: AppColors.accent),
            ],
          ),
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
                : const [
                    BoxShadow(
                        color: AppColors.primaryDark, offset: Offset(0, 5))
                  ],
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
