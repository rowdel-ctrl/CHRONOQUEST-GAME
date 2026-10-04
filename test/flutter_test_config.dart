import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Widget tests default to a 10-minute timeout, so a test that awaits a real
/// async operation (Hive, file I/O) inside the fake-time zone looks frozen
/// instead of failing. A minute is far longer than any test here needs.
class _FailFastBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  Timeout get defaultTestTimeout => const Timeout(Duration(seconds: 60));
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  _FailFastBinding();
  await testMain();
}
