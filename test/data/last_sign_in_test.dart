// The phone remembers the class code and username of the last sign-in (never the
// password), so "Balik na ako" only has to ask for the password. It must survive
// logout, which clears the student's data but keeps each student's wallet and the
// settings that belong to the phone.
import 'dart:io';

import 'package:chronoquest/models/control_scheme.dart';
import 'package:chronoquest/models/hearts_state.dart';
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

  test('logout keeps it', () async {
    await StorageService.saveLastSignIn('EDG5A1', 'JuanNinja99');

    await StorageService.clearAll();

    final last = StorageService.getLastSignIn();
    expect(last, isNotNull, reason: 'the next sign-in only asks for the password');
    expect((last!.classCode, last.username), ('EDG5A1', 'JuanNinja99'));
  });

  group('logout and the rest of the phone', () {
    test('keeps every student\'s hearts, so logging out is no way to refill them', () async {
      await StorageService.saveHeartsStateFor('s1', const HeartsState(count: 1, regenStartMs: 99));
      await StorageService.saveHeartsStateFor('s2', const HeartsState(count: 4));

      await StorageService.clearAll();

      expect(StorageService.getHeartsStateFor('s1').count, 1);
      expect(StorageService.getHeartsStateFor('s1').regenStartMs, 99);
      expect(StorageService.getHeartsStateFor('s2').count, 4);
    });

    test('keeps every student\'s wallet, so coins survive a logout', () async {
      await StorageService.saveWallet('s1', {'coins': 340, 'unlocked': ['luna']});
      await StorageService.saveWallet('s2', {'coins': 15});

      await StorageService.clearAll();

      expect(StorageService.getWallet('s1'), {'coins': 340, 'unlocked': ['luna']});
      expect(StorageService.getWallet('s2'), {'coins': 15});
    });

    test('keeps the settings that belong to the phone', () async {
      await StorageService.setSoundEnabled(false);
      await StorageService.setMusicEnabled(false);
      await StorageService.setSoundVolume(0.4);
      await StorageService.setMusicVolume(0.2);
      await StorageService.setControlScheme(ControlScheme.arrows);
      await StorageService.markTutorialSeen();
      await StorageService.setUnlockAll(true);

      await StorageService.clearAll();

      expect(StorageService.getSoundEnabled(), isFalse);
      expect(StorageService.getMusicEnabled(), isFalse);
      expect(StorageService.getSoundVolume(), 0.4);
      expect(StorageService.getMusicVolume(), 0.2);
      expect(StorageService.getControlScheme(), ControlScheme.arrows);
      expect(StorageService.hasSeenTutorial(), isTrue);
      expect(StorageService.getUnlockAll(), isTrue, reason: 'a tester stays in Test Mode');
    });

    test('wipes what is per phone, so the next student starts clean', () async {
      await StorageService.saveCharacter('luna');
      await StorageService.saveLevelCompleted('spanish', 3, 2);
      await StorageService.cacheEraProgress('spanish', {'done': 3});
      await StorageService.saveHeartsState(const HeartsState(count: 2, regenStartMs: 123));
      await StorageService.queuePendingResult({'level': 1});
      await StorageService.saveQuestionCache({'classCode': 'EDG5A1'});

      await StorageService.clearAll();

      expect(StorageService.getCharacter(), 'rizal', reason: 'back to the default');
      expect(StorageService.getCompletedLevels('spanish'), isEmpty);
      expect(StorageService.getCachedEraProgress('spanish'), isNull);
      expect(StorageService.getHeartsState().count, HeartsState.initial().count);
      expect(StorageService.getPendingResults(), isEmpty);
      expect(StorageService.getQuestionCache(), isNull);
    });
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
