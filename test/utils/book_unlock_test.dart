// Which book comes unchained when a boss falls, and the mark that makes the chain break play once.
import 'dart:io';

import 'package:chronoquest/services/storage_service.dart';
import 'package:chronoquest/utils/book_unlock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir =
      Directory.systemTemp.createTempSync('chronoquest_book_unlock_').path;

  setUpAll(() async {
    Hive.init(dir);
    await Hive.openBox('chronoquest');
    // Logging out also clears the secure storage, which has no phone to talk to here.
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

  setUp(() async {
    await StorageService.appBox.clear();
    StorageService.resetPendingBookForTesting();
  });

  group('which book comes free', () {
    test(
        'Grade 5: Sinaunang Pilipinas opens Pananakop ng Espanya, which opens Pag-usbong ng Nasyonalismo, which opens nothing',
        () {
      expect(BookUnlock.nextEraId('pre-colonial', 'grade5'), 'spanish');
      expect(BookUnlock.nextEraId('spanish', 'grade5'), 'nationalism');
      expect(BookUnlock.nextEraId('nationalism', 'grade5'), isNull);
    });

    test('Grade 6 has its own three', () {
      expect(BookUnlock.nextEraId('american', 'grade6'), 'ww2');
      expect(BookUnlock.nextEraId('ww2', 'grade6'), 'modern');
      expect(BookUnlock.nextEraId('modern', 'grade6'), isNull);
    });

    test(
        "an era that is not in the student's grade opens nothing, and no grade means Grade 5",
        () {
      expect(BookUnlock.nextEraId('american', 'grade5'), isNull);
      expect(BookUnlock.nextEraId('pre-colonial', null), 'spanish');
      expect(BookUnlock.nextEraId('nope', 'grade5'), isNull);
    });

    test('the replay button unchains the second book of the grade', () {
      expect(BookUnlock.replayEraId('grade5'), 'spanish');
      expect(BookUnlock.replayEraId('grade6'), 'ww2');
    });
  });

  group('the mark', () {
    test('nothing is waiting on a new phone', () {
      expect(StorageService.getPendingBookUnlock(), isNull);
    });

    test('the first time a boss is beaten the next book is marked', () async {
      final marked = await BookUnlock.markAfterBoss(
          eraId: 'pre-colonial',
          gradeLevel: 'grade5',
          isGuest: false,
          firstClear: true);
      expect(marked, 'spanish');
      expect(StorageService.getPendingBookUnlock(), 'spanish');
    });

    test('beating it again marks nothing (the book is open already)', () async {
      final marked = await BookUnlock.markAfterBoss(
          eraId: 'pre-colonial',
          gradeLevel: 'grade5',
          isGuest: false,
          firstClear: false);
      expect(marked, isNull);
      expect(StorageService.getPendingBookUnlock(), isNull);
    });

    test('a guest has the first era only: nothing is marked', () async {
      final marked = await BookUnlock.markAfterBoss(
          eraId: 'pre-colonial',
          gradeLevel: 'grade5',
          isGuest: true,
          firstClear: true);
      expect(marked, isNull);
      expect(StorageService.getPendingBookUnlock(), isNull);
    });

    test('the last era of a grade has no next book', () async {
      final marked = await BookUnlock.markAfterBoss(
          eraId: 'nationalism',
          gradeLevel: 'grade5',
          isGuest: false,
          firstClear: true);
      expect(marked, isNull);
    });

    test('the mark can be set and cleared', () async {
      await StorageService.setPendingBookUnlock('spanish');
      expect(StorageService.getPendingBookUnlock(), 'spanish');
      await StorageService.setPendingBookUnlock(null);
      expect(StorageService.getPendingBookUnlock(), isNull);
    });

    test('it is also in the file, so it survives closing the app', () async {
      await StorageService.setPendingBookUnlock('spanish');
      StorageService.resetPendingBookForTesting(); // as if the app had just started
      expect(StorageService.getPendingBookUnlock(), 'spanish');
    });

    test('logging out clears it', () async {
      await StorageService.setPendingBookUnlock('spanish');
      await StorageService.clearAll();
      expect(StorageService.getPendingBookUnlock(), isNull);
    });
  });
}
