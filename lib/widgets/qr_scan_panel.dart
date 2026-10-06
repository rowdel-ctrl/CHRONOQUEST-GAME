import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/constants.dart';
import '../utils/join_link.dart';
import 'game_ui.dart';

/// Why the camera could not be used.
enum ScanFailure { denied, other }

/// Builds the live camera view. It calls [onRaw] with the text of every code it
/// sees and [onFailure] once if the camera cannot start. Replaceable so tests do
/// not need a camera or the plugin.
typedef ScannerViewBuilder = Widget Function(
  BuildContext context,
  ValueChanged<String> onRaw,
  ValueChanged<ScanFailure> onFailure,
);

/// The real camera, through `mobile_scanner`. Only QR codes are looked for.
Widget cameraScannerView(
  BuildContext context,
  ValueChanged<String> onRaw,
  ValueChanged<ScanFailure> onFailure,
) =>
    _CameraView(onRaw: onRaw, onFailure: onFailure);

class _CameraView extends StatefulWidget {
  final ValueChanged<String> onRaw;
  final ValueChanged<ScanFailure> onFailure;
  const _CameraView({required this.onRaw, required this.onFailure});

  @override
  State<_CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<_CameraView> {
  final _controller =
      MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        for (final barcode in capture.barcodes) {
          final raw = barcode.rawValue;
          if (raw != null) widget.onRaw(raw);
        }
      },
      errorBuilder: (context, error) {
        if (!_failed) {
          _failed = true;
          final failure =
              error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? ScanFailure.denied
                  : ScanFailure.other;
          // Reported after this frame: it changes the parent's state.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onFailure(failure);
          });
        }
        return const ColoredBox(color: Colors.black);
      },
    );
  }
}

/// The camera view with its frame: corner brackets, a hint, and a short message
/// when the code is not a ChronoQuest one. It keeps scanning after a wrong code.
///
/// Calls [onCode] once with the class code of the first good scan.
class QrScanner extends StatefulWidget {
  final ValueChanged<String> onCode;
  final ValueChanged<ScanFailure> onFailure;
  final ScannerViewBuilder scannerBuilder;

  /// How big the camera square is, at most.
  final double maxSize;

  const QrScanner({
    super.key,
    required this.onCode,
    required this.onFailure,
    this.scannerBuilder = cameraScannerView,
    this.maxSize = 150,
  });

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  bool _delivered = false;
  bool _wrong = false;
  Timer? _clearWrong;

  @override
  void dispose() {
    _clearWrong?.cancel();
    super.dispose();
  }

  void _onRaw(String raw) {
    if (_delivered) return;
    final code = parseJoinCode(raw);
    if (code != null) {
      _delivered = true;
      widget.onCode(code);
      return;
    }
    if (!_wrong && mounted) setState(() => _wrong = true);
    _clearWrong?.cancel();
    _clearWrong = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _wrong = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Text and brackets grow with the camera square (a phone's is 136).
    final k = (widget.maxSize / 136).clamp(1.0, 2.0).toDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: widget.maxSize, maxHeight: widget.maxSize),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child:
                      widget.scannerBuilder(context, _onRaw, widget.onFailure),
                ),
                IgnorePointer(child: _Corners(scale: k)),
                if (_wrong)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8 * k, vertical: 5 * k),
                      color: AppColors.danger,
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 14 * k, color: Colors.white),
                          SizedBox(width: 6 * k),
                          Expanded(
                            child: Text(
                              'Hindi ito QR ng ChronoQuest. Subukan ulit.',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10 * k,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2),
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
        SizedBox(height: 6 * k),
        Text(
          'Itapat sa QR code ng titser',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12 * k),
        ),
      ],
    );
  }
}

class _Corners extends StatelessWidget {
  final double scale;
  const _Corners({this.scale = 1});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _CornerPainter(scale));
}

class _CornerPainter extends CustomPainter {
  final double scale;
  _CornerPainter(this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.square;
    final inset = 8.0 * scale, len = 26.0 * scale;
    final l = inset, t = inset, r = size.width - inset, b = size.height - inset;
    for (final (x, y, dx, dy) in [
      (l, t, 1.0, 1.0),
      (r, t, -1.0, 1.0),
      (l, b, 1.0, -1.0),
      (r, b, -1.0, -1.0),
    ]) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * len, y), p);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * len), p);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.scale != scale;
}

enum _PanelState { idle, scanning, done, failed }

/// The scan card that sits where the logo used to be on the login screen.
///
/// The camera stays off until the student taps it, so there is no permission
/// pop-up when the app opens and nothing runs while they type. A good scan stops
/// the camera, shows the code, and calls [onCode]; the Class Code field it fills
/// stays editable.
class QrScanPanel extends StatefulWidget {
  final ValueChanged<String> onCode;
  final ScannerViewBuilder scannerBuilder;

  const QrScanPanel({
    super.key,
    required this.onCode,
    this.scannerBuilder = cameraScannerView,
  });

  @override
  State<QrScanPanel> createState() => _QrScanPanelState();
}

class _QrScanPanelState extends State<QrScanPanel> {
  _PanelState _state = _PanelState.idle;
  String? _code;
  ScanFailure? _failure;

  /// How much bigger than the phone layout the card is drawn. A phone gets 1;
  /// a tablet has room, and a 150-pixel camera looked lost there.
  double _s = 1;

  void _start() => setState(() {
        _state = _PanelState.scanning;
        _failure = null;
      });

  void _got(String code) {
    setState(() {
      _code = code;
      _state = _PanelState.done;
    });
    widget.onCode(code);
  }

  void _failed(ScanFailure failure) => setState(() {
        _failure = failure;
        _state = _PanelState.failed;
      });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final height = MediaQuery.sizeOf(context).height;
      final width = box.maxWidth.isFinite ? box.maxWidth : 300.0;
      // Fit the column it sits in, and leave the form room above and below.
      _s = (width / 300).clamp(1.0, 1.8).toDouble();
      _s = _s < height / 380 ? _s : (height / 380).clamp(1.0, 1.8).toDouble();
      return _card(context);
    });
  }

  Widget _card(BuildContext context) {
    final scanning = _state == _PanelState.scanning;
    final done = _state == _PanelState.done;
    return Container(
      constraints: BoxConstraints(maxWidth: 300 * _s),
      padding: EdgeInsets.all((scanning ? 10 : 12) * _s),
      decoration: BoxDecoration(
        color: scanning
            ? Colors.black
            : done
                ? AppColors.success.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: done
              ? AppColors.success
              : scanning
                  ? Colors.black
                  : AppColors.accent,
          width: 2,
        ),
      ),
      child: switch (_state) {
        _PanelState.idle => _idle(),
        _PanelState.scanning => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrScanner(
                maxSize: 136 * _s,
                onCode: _got,
                onFailure: _failed,
                scannerBuilder: widget.scannerBuilder,
              ),
              _link('Isara', () => setState(() => _state = _PanelState.idle)),
            ],
          ),
        _PanelState.done => _done(),
        _PanelState.failed => _failedView(),
      },
    );
  }

  Widget _idle() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner, size: 40 * _s, color: AppColors.accent),
          SizedBox(height: 6 * _s),
          _title('I-scan ang QR ng titser'),
          SizedBox(height: 3 * _s),
          _sub('Hindi mo na kailangang i-type ang class code'),
          SizedBox(height: 8 * _s),
          GameButton(
            label: 'BUKSAN ANG CAMERA',
            fontSize: 10 * _s,
            minHeight: 44 * _s,
            icon: Icons.photo_camera,
            onPressed: _start,
          ),
        ],
      );

  Widget _done() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56 * _s,
            height: 56 * _s,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
            child: Icon(Icons.check, size: 38 * _s, color: Colors.white),
          ),
          SizedBox(height: 8 * _s),
          Text(
            'Nakuha na ang class code',
            style: GoogleFonts.poppins(
                color: const Color(0xFF8BE08A),
                fontWeight: FontWeight.bold,
                fontSize: 15 * _s),
          ),
          SizedBox(height: 6 * _s),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14 * _s, vertical: 4 * _s),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.primaryDark, width: 2),
            ),
            child: Text(
              _code ?? '',
              style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17 * _s,
                  letterSpacing: 2),
            ),
          ),
          _link('I-scan ulit', _start),
        ],
      );

  Widget _failedView() {
    final denied = _failure == ScanFailure.denied;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.no_photography, size: 46 * _s, color: const Color(0xFFC9A9A6)),
        SizedBox(height: 8 * _s),
        _title(
            denied ? 'Walang pahintulot sa camera' : 'Hindi mabuksan ang camera'),
        SizedBox(height: 4 * _s),
        _sub(denied
            ? 'Payagan ang camera sa Settings ng phone. Pwede pa ring i-type ang class code.'
            : 'Pwede pa ring i-type ang class code.'),
        SizedBox(height: 8 * _s),
        _link('Subukan ulit', _start),
      ],
    );
  }

  Widget _title(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15 * _s,
            height: 1.3),
      );

  Widget _sub(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
            color: Colors.white70, fontSize: 12 * _s, height: 1.4),
      );

  Widget _link(String text, VoidCallback onTap) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: Size(48, 32 * _s),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          foregroundColor: AppColors.accent,
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
              fontSize: 12 * _s,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline),
        ),
      );
}

/// Full-screen scanner for phones too narrow to have the left-hand card. Closes
/// itself on a good scan and returns the class code, or null if dismissed.
Future<String?> showQrScanSheet(
  BuildContext context, {
  ScannerViewBuilder scannerBuilder = cameraScannerView,
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _QrScanSheet(scannerBuilder: scannerBuilder),
    ),
  );
}

class _QrScanSheet extends StatefulWidget {
  final ScannerViewBuilder scannerBuilder;
  const _QrScanSheet({required this.scannerBuilder});

  @override
  State<_QrScanSheet> createState() => _QrScanSheetState();
}

class _QrScanSheetState extends State<_QrScanSheet> {
  ScanFailure? _failure;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('I-scan ang QR',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Center(
        child: _failure == null
            ? SingleChildScrollView(
                child: QrScanner(
                  maxSize: 220,
                  scannerBuilder: widget.scannerBuilder,
                  onCode: (code) => Navigator.of(context).pop(code),
                  onFailure: (f) => setState(() => _failure = f),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _failure == ScanFailure.denied
                      ? 'Walang pahintulot sa camera. Payagan ito sa Settings ng phone, o i-type na lang ang class code.'
                      : 'Hindi mabuksan ang camera. I-type na lang ang class code.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 14, height: 1.5),
                ),
              ),
      ),
    );
  }
}
