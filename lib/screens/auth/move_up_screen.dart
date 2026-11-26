import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../models/class_move.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';
import '../../widgets/qr_scan_panel.dart';
import 'auth_widgets.dart';
import 'welcome_screen.dart' show firstNameOf;

/// What this screen needs from the sign-in screen: the sign-in that was refused because the
/// class has ended. Kept in memory only (it goes through the router, nothing is saved), and
/// used once, to move the learner to the new class.
class MoveUpArgs {
  final String classCode;
  final String username;
  final String password;
  final ClassEndedInfo info;
  const MoveUpArgs({
    required this.classCode,
    required this.username,
    required this.password,
    required this.info,
  });
}

/// Shown on the sign-in screen after "I don't have a code".
const String askTeacherForNewCode =
    'Itanong sa teacher mo ang bagong class code. Pag meron ka na, mag-login ulit.';

/// Asks the server about a class code. Throws a message that is ready to show.
Future<ClassInfo> lookUpClass(String classCode) =>
    ApiService().classLookup(classCode);

enum _Phase { code, confirm, sessionActive, welcome }

/// A learner whose class has ended keeps the same account and joins the new class with its
/// code: type the new code, check it is the right class, then move. Points, coins and
/// characters come along.
class MoveUpScreen extends ConsumerStatefulWidget {
  final MoveUpArgs args;

  /// Tests pass a fake; the app asks the server.
  final Future<ClassInfo> Function(String classCode) lookup;

  /// The camera view for QR scanning. Tests pass a fake; the app uses the camera.
  final ScannerViewBuilder scannerBuilder;

  const MoveUpScreen({
    super.key,
    required this.args,
    this.lookup = lookUpClass,
    this.scannerBuilder = cameraScannerView,
  });

  static const backKey = ValueKey('moveup_back');
  static const codeKey = ValueKey('moveup_code');
  static const scanKey = ValueKey('moveup_scan');
  static const goKey = ValueKey('moveup_go');
  static const noCodeKey = ValueKey('moveup_no_code');
  static const classCardKey = ValueKey('moveup_class');
  static const yesKey = ValueKey('moveup_yes');
  static const noKey = ValueKey('moveup_no');
  static const sessionGoOnKey = ValueKey('moveup_session_go_on');
  static const sessionCancelKey = ValueKey('moveup_session_cancel');
  static const endedKey = ValueKey('moveup_ended');
  static const welcomeKey = ValueKey('moveup_welcome');
  static const usernameKey = ValueKey('moveup_username');
  static const startKey = ValueKey('moveup_start');

  @override
  ConsumerState<MoveUpScreen> createState() => _MoveUpScreenState();
}

class _MoveUpScreenState extends ConsumerState<MoveUpScreen> {
  final _code = TextEditingController();
  _Phase _phase = _Phase.code;
  bool _busy = false;
  String? _error;

  /// The code that was looked up, and the class it belongs to.
  String _askedCode = '';
  ClassInfo? _class;
  MoveUpResult? _result;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  ClassEndedInfo get _info => widget.args.info;

  /// Step 1 to 2: "Is this your class?"
  Future<void> _lookup() async {
    if (_busy) return;
    final code = _code.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'I-type ang bagong class code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final found = await widget.lookup(code);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _askedCode = code;
        _class = found;
        _phase = _Phase.confirm;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is String ? e : 'May problema. Subukan ulit.';
      });
    }
  }

  /// Step 3: move. [takeOver] when the account is open on another phone and the learner
  /// said to use it here.
  Future<void> _move({bool takeOver = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(authProvider.notifier).moveUp(
            oldClassCode: widget.args.classCode,
            username: widget.args.username,
            password: widget.args.password,
            newClassCode: _askedCode,
            takeOver: takeOver,
            oldGrade: _info.grade,
            newGrade: _class?.grade,
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = result;
        _phase = _Phase.welcome;
      });
    } on MoveUpError catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (e.code == 'SESSION_ACTIVE') {
          _phase = _Phase.sessionActive;
        } else {
          _error = e.message;
          _phase = _Phase.confirm;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'May problema. Subukan ulit.';
        _phase = _Phase.confirm;
      });
    }
  }

  void _back() {
    switch (_phase) {
      case _Phase.code:
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/login');
        }
      case _Phase.confirm:
        setState(() {
          _phase = _Phase.code;
          _error = null;
        });
      case _Phase.sessionActive:
        setState(() => _phase = _Phase.confirm);
      case _Phase.welcome:
        break; // the move is done: there is no going back
    }
  }

  /// "I don't have a code": the sign-in screen, which says to ask the teacher.
  void _noCode() => context.go('/login', extra: askTeacherForNewCode);

  Future<void> _scan() async {
    final code =
        await showQrScanSheet(context, scannerBuilder: widget.scannerBuilder);
    if (code != null && mounted) {
      setState(() {
        _code.text = code;
        _error = null;
      });
    }
  }

  void _start() {
    final student = _result?.student;
    context.go(student?.mustChangePassword == true
        ? '/change-password'
        : '/character-selection');
  }

  String get _say => switch (_phase) {
        _Phase.code => _busy
            ? 'Sandali lang, hinahanap ko…'
            : 'Dala mo pa rin ang points at progress mo!',
        _Phase.confirm =>
          _busy ? 'Sandali lang, lilipat na tayo…' : 'Tingnan mo kung tama.',
        _Phase.sessionActive => 'Sandali lang!',
        _Phase.welcome => 'Tuloy ang laro!',
      };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 560;
    final form = switch (_phase) {
      _Phase.code => _codeForm(wide),
      _Phase.confirm => _confirmForm(),
      _Phase.sessionActive => _sessionForm(),
      _Phase.welcome => _welcomeForm(),
    };

    return PopScope(
      // Back never undoes a move that is done; before that it steps back one question.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: GameBackdrop(
          baseColor: AppColors.background,
          child: SafeArea(
            child: Stack(
              children: [
                if (_phase != _Phase.welcome)
                  Positioned(
                    left: 8,
                    top: 4,
                    child: MenuChip(
                      key: MoveUpScreen.backKey,
                      icon: PixelGlyph.back,
                      tooltip: 'Bumalik',
                      onTap: _back,
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
                                      AuthGuide(
                                          say: _say, fontSize: 14, sprite: 96),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 28),
                                Flexible(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 480),
                                    child: form,
                                  ),
                                ),
                              ],
                            )
                          : ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: form,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 21,
          height: 1.25,
          fontWeight: FontWeight.bold,
          color: AppColors.surface,
        ),
      );

  /// "Tapos na ang klase mo na Sampaguita (2025-2026)."
  String _endedLine() {
    final name = _info.name == null ? '' : firstNameOf(_info.name!);
    final from = [
      if (_info.sectionName != null) _info.sectionName!,
      if (_info.schoolYear != null) '(${_info.schoolYear})',
    ].join(' ');
    final hi = name.isEmpty ? 'Hi!' : 'Hi $name!';
    final ended = from.isEmpty
        ? 'Tapos na ang klase mo.'
        : 'Tapos na ang klase mo na $from.';
    return '$hi $ended I-type ang bago mong class code para dala mo pa rin '
        'ang points at progress mo.';
  }

  /// Step 1: the new class code.
  Widget _codeForm(bool wide) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Tapos na ang klase mo.'),
        const SizedBox(height: 8),
        Text(
          _endedLine(),
          key: MoveUpScreen.endedKey,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            height: 1.4,
            color: AppColors.surface,
          ),
        ),
        const SizedBox(height: 12),
        AuthField(
          key: MoveUpScreen.codeKey,
          controller: _code,
          hint: 'EDG6A1',
          state: _error != null ? AuthFieldState.bad : AuthFieldState.normal,
          autofocus: true,
          capitalization: TextCapitalization.characters,
          action: TextInputAction.done,
          trailing: IconButton(
            key: MoveUpScreen.scanKey,
            tooltip: 'I-scan ang QR',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: const Icon(Icons.qr_code_scanner,
                color: AppColors.primary, size: 26),
            onPressed: _busy ? null : _scan,
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: _lookup,
        ),
        const SizedBox(height: 10),
        if (_error != null)
          AuthError(_error!)
        else
          const AuthHelp('Ibibigay ito ng teacher mo, o i-scan ang QR.'),
        const SizedBox(height: 12),
        _busy
            ? const AuthBusyButton(label: 'HINAHANAP…')
            : GameButton(
                key: MoveUpScreen.goKey,
                label: 'TULOY',
                fontSize: 13,
                width: double.infinity,
                onPressed: _lookup,
              ),
        const SizedBox(height: 12),
        GameButton(
          key: MoveUpScreen.noCodeKey,
          label: 'WALA AKONG CODE',
          fontSize: 12,
          minHeight: 44,
          width: double.infinity,
          color: AppColors.surface,
          onPressed: _busy ? null : _noCode,
        ),
      ],
    );
  }

  /// Step 2: "Is this your class?"
  Widget _confirmForm() {
    final found = _class;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Ito ba ang klase mo?'),
        const SizedBox(height: 10),
        if (found != null)
          _ClassCard(key: MoveUpScreen.classCardKey, info: found),
        const SizedBox(height: 12),
        if (_error != null) ...[AuthError(_error!), const SizedBox(height: 12)],
        _busy
            ? const AuthBusyButton(label: 'LILIPAT…')
            : GameButton(
                key: MoveUpScreen.yesKey,
                label: 'OO, ITO ANG KLASE KO',
                fontSize: 13,
                width: double.infinity,
                onPressed: _move,
              ),
        const SizedBox(height: 12),
        GameButton(
          key: MoveUpScreen.noKey,
          label: 'HINDI, BUMALIK',
          fontSize: 12,
          minHeight: 44,
          width: double.infinity,
          color: AppColors.surface,
          onPressed: _busy ? null : _back,
        ),
      ],
    );
  }

  /// The account is open on another phone: going on logs that phone out.
  Widget _sessionForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Gamit na ang account mo sa ibang device.'),
        const SizedBox(height: 12),
        const AuthHelp('Isang device lang ang puwede sa isang account. '
            'Kung ituloy mo rito, ma-lo-logout ang kabilang device.'),
        const SizedBox(height: 14),
        _busy
            ? const AuthBusyButton(label: 'SANDALI LANG…')
            : GameButton(
                key: MoveUpScreen.sessionGoOnKey,
                label: 'ITULOY DITO',
                fontSize: 13,
                width: double.infinity,
                onPressed: () => _move(takeOver: true),
              ),
        const SizedBox(height: 14),
        GameButton(
          key: MoveUpScreen.sessionCancelKey,
          label: 'HUWAG NA',
          fontSize: 13,
          width: double.infinity,
          color: AppColors.surface,
          onPressed: _busy ? null : _back,
        ),
      ],
    );
  }

  /// Done: the new class, what came along, and the username if it changed.
  Widget _welcomeForm() {
    final result = _result;
    final student = result?.student;
    final section = result?.section?.sectionName.isNotEmpty == true
        ? result!.section!.sectionName
        : (_class?.sectionName ?? '');
    final usernameChanged = student != null &&
        student.username.isNotEmpty &&
        student.username != widget.args.username;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                section.isEmpty
                    ? 'Welcome sa bagong klase!'
                    : 'Welcome sa $section!',
                key: MoveUpScreen.welcomeKey,
                style: GoogleFonts.poppins(
                  fontSize: 21,
                  height: 1.25,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const AuthHelp('Dala mo pa rin ang lahat ng nakuha mo:'),
        const SizedBox(height: 10),
        if (student != null)
          Row(
            children: [
              Expanded(
                  child:
                      AuthReadout(label: 'POINTS', value: '${student.score}')),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      AuthReadout(label: 'COINS', value: '${student.coins}')),
              const SizedBox(width: 10),
              Expanded(
                child: AuthReadout(
                    label: 'HEROES',
                    value: '${student.unlockedCharacters.length}'),
              ),
            ],
          ),
        if (usernameChanged) ...[
          const SizedBox(height: 12),
          AuthReadout(label: 'BAGO ANG USERNAME MO', value: student.username),
          const SizedBox(height: 6),
          const AuthHelp(
            'May kapareho ka ng username sa bagong klase, kaya dinagdagan ng numero. '
            'Ito na ang gamitin mo sa susunod na login.',
            good: true,
          ),
        ],
        const SizedBox(height: 14),
        GameButton(
          key: MoveUpScreen.startKey,
          label: 'TULOY',
          fontSize: 13,
          width: double.infinity,
          onPressed: _start,
        ),
      ],
    );
  }
}

/// The new class as a small card: the section first, then teacher, school and year.
class _ClassCard extends StatelessWidget {
  final ClassInfo info;
  const _ClassCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final yearAndGrade = [
      if (info.schoolYear.isNotEmpty) info.schoolYear,
      if (info.grade.isNotEmpty) info.grade,
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EBCB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryDark, width: 3),
        boxShadow: const [
          BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            info.sectionName.isEmpty ? info.classCode : info.sectionName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (yearAndGrade.isNotEmpty) _row('SCHOOL YEAR', yearAndGrade),
          if (info.teacherName.isNotEmpty) _row('TEACHER', info.teacherName),
          if (info.schoolName.isNotEmpty) _row('SCHOOL', info.schoolName),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.9,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
}
