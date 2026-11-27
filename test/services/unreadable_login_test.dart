// A phone can put the saved login back after a reinstall without the key that
// opens it (Android backup). Every read then fails with BAD_DECRYPT. That used to
// leave the app stuck on its first screen; now the file is wiped and the student
// is simply "not logged in".
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> calls;
  late bool broken;
  late String? stored;

  setUp(() {
    calls = [];
    broken = true;
    stored = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add(call.method);
      if (broken && call.method != 'deleteAll') {
        throw PlatformException(
            code: 'Exception encountered',
            message: 'javax.crypto.BadPaddingException: BAD_DECRYPT');
      }
      if (call.method == 'deleteAll') {
        broken = false; // a wiped file is readable again
        stored = null;
      }
      if (call.method == 'write') stored = call.arguments['value'] as String?;
      if (call.method == 'read') return stored;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('an unreadable saved login counts as "not logged in" and is wiped',
      () async {
    expect(await StorageService.hasToken(), isFalse);
    expect(calls, contains('deleteAll'));
  });

  test('the next read after the wipe works', () async {
    expect(await StorageService.getToken(), isNull);
    await StorageService.saveToken('abc');
    expect(await StorageService.getToken(), 'abc');
    expect(await StorageService.hasToken(), isTrue);
  });

  test('saving a login over an unreadable file wipes it and saves', () async {
    await StorageService.saveToken('xyz');
    expect(stored, 'xyz');
  });

  test('clearing the login does not throw on an unreadable file', () async {
    await StorageService.clearToken();
    expect(calls, contains('deleteAll'));
  });
}
