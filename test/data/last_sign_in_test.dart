// The phone remembers the class code and username of the last sign-in (never the
// password), so "Balik na ako" only has to ask for the password. It must survive
// logout, which clears everything else.
import 'dart:io';

import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = Directory.systemTemp.createTempSync('chronoquest_last_sign_in_').path;

  setUpAll(() async {
    Hive.init(dir);
    await Hive.openBox('chronoquest');
    // logout also clears the secure storage, which has no phone to talk to here.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      Directory(dir).deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async => StorageService.appBox.clear());

  test('a phone that has never signed in remembers nothing', () {
    expect(StorageService.getLastSignIn(), isNull);
  });

  test('remembers the class code and username', () async {
    await StorageService.saveLastSignIn('EDG5A1', 'JuanNinja99');

    final last = StorageService.getLastSignIn();
    expect(last, isNotNull);
    expect((last!.classCode, last.username), ('EDG5A1', 'JuanNinja99'));
  });

  test('the next sign-in replaces it', () async {
    await StorageService.saveLastSignIn('EDG5A1', 'JuanNinja99');
    await StorageService.saveLastSignIn('XYZ789', 'maria');

    final last = StorageService.getLastSignIn()!;
    expect((last.classCode, last.username), ('XYZ789', 'maria'));
  });

  test('half an answer counts as nothing', () async {
    await StorageService.appBox.put('last_class_code', 'EDG5A1');
    expect(StorageService.getLastSignIn(), isNull, reason: 'no username saved');
  });

  test('logout keeps it and clears everything else', () async {
    await StorageService.saveLastSignIn('EDG5A1', 'JuanNinja99');
    await StorageService.saveCharacter('luna');
    await StorageService.setUnlockAll(true);

    await StorageService.clearAll();

    final last = StorageService.getLastSignIn();
    expect(last, isNotNull, reason: 'the next sign-in only asks for the password');
    expect((last!.classCode, last.username), ('EDG5A1', 'JuanNinja99'));
    expect(StorageService.getCharacter(), 'rizal', reason: 'back to the default');
    expect(StorageService.getUnlockAll(), isFalse);
  });

  test('logout on a phone that remembers nothing leaves it that way', () async {
    await StorageService.clearAll();
    expect(StorageService.getLastSignIn(), isNull);
  });

  test('the password is never stored', () async {
    await StorageService.saveLastSignIn('EDG5A1', 'JuanNinja99');
    final keys = StorageService.appBox.keys.map((k) => '$k'.toLowerCase());
    expect(keys.any((k) => k.contains('password')), isFalse);
  });
}
