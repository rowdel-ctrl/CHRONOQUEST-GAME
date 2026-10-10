import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/dio_client.dart';

/// The time hearts are counted in: the server's, not the phone's.
///
/// The phone's clock belongs to the student, and moving it forward used to bring
/// every heart back at once. Here the server's time is read and then carried
/// forward with a [Stopwatch], which keeps its own time: changing the phone's
/// clock does not move it. The phone's clock is only used to notice that it has
/// jumped (or that the phone slept), and the only thing that causes is another
/// read from the server.
///
/// Until a read has succeeded there is no trusted time ([now] is null) and hearts
/// do not come back. They start counting again once the game gets online.
class ServerClock {
  ServerClock({Future<int?> Function()? fetch}) : _fetch = fetch ?? _fromServer;

  /// A clock that is already synced to [serverNow], for tests.
  @visibleForTesting
  ServerClock.fixed(DateTime serverNow) : _fetch = _nothing {
    _set(serverNow.millisecondsSinceEpoch);
  }

  static final ServerClock instance = ServerClock();

  /// How long a read stays good before the next one.
  static const Duration recheckAfter = Duration(minutes: 1);

  /// The shortest wait between two attempts, so being offline is not a loop.
  static const Duration retryAfter = Duration(seconds: 20);

  /// How far the phone's clock may disagree with the stopwatch before it counts
  /// as having jumped.
  static const Duration tolerance = Duration(seconds: 5);

  final Future<int?> Function() _fetch;
  final Stopwatch _since = Stopwatch();
  final Stopwatch _attempt = Stopwatch();
  int? _serverMsAtSync;
  DateTime _phoneAtSync = DateTime.now();
  bool _syncing = false;

  bool get isSynced => _serverMsAtSync != null;

  /// The server's time now, or null if it has not been read yet.
  DateTime? get now => _serverMsAtSync == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          _serverMsAtSync! + _since.elapsedMilliseconds,
        );

  /// Reads the server's time. Never throws; a failed read leaves the clock as
  /// it was.
  Future<void> sync() async {
    if (_syncing) return;
    _syncing = true;
    _attempt
      ..reset()
      ..start();
    try {
      final trip = Stopwatch()..start();
      final ms = await _fetch();
      if (ms != null) _set(ms + trip.elapsedMilliseconds ~/ 2);
    } catch (_) {
      // Offline: carry on with what there is.
    } finally {
      _syncing = false;
    }
  }

  /// Reads again if there is no time yet, the last read is old, or the phone's
  /// clock and the stopwatch have come apart. Cheap to call often.
  void syncIfNeeded() {
    if (_syncing) return;
    if (_attempt.isRunning && _attempt.elapsed < retryAfter) return;
    if (!isSynced) {
      sync();
      return;
    }
    final phoneGap = DateTime.now().difference(_phoneAtSync);
    final jumped = phoneGap.isNegative ||
        (phoneGap - _since.elapsed).abs() > tolerance;
    if (jumped || _since.elapsed > recheckAfter) sync();
  }

  void _set(int serverMs) {
    _serverMsAtSync = serverMs;
    _since
      ..reset()
      ..start();
    _phoneAtSync = DateTime.now();
  }

  static Future<int?> _nothing() async => null;

  static Future<int?> _fromServer() async {
    try {
      final response = await DioClient.instance.get(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final data = response.data;
      final ms = data is Map ? data['serverTimeMs'] : null;
      return ms is int ? ms : null;
    } catch (_) {
      return null;
    }
  }
}
