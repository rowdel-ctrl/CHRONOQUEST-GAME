// The temporary "open every era and level" testing switch. It must default
// to off (a normal student never sees everything unlocked) and survive a
// restart, since it is meant to be turned on once and left on while testing.
import 'dart:io';

import 'package:chronoquest/providers/unlock_all_provider.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  final dir = Directory.systemTemp.createTempSync('chronoquest_unlock_test_').path;

  setUpAll(() async {
    Hive.init(dir);
    await Hive.openBox('chronoquest');
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      Directory(dir).deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async => StorageService.appBox.clear());

  test('is off by default', () {
    expect(StorageService.getUnlockAll(), isFalse);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(unlockAllProvider), isFalse);
  });

  test('turning it on is saved', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(unlockAllProvider.notifier).set(true);

    expect(container.read(unlockAllProvider), isTrue);
    expect(StorageService.getUnlockAll(), isTrue);
  });

  test('a fresh provider after a restart still reads it as on', () async {
    await StorageService.setUnlockAll(true);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(unlockAllProvider), isTrue);
  });

  test('turning it off again is saved', () async {
    await StorageService.setUnlockAll(true);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(unlockAllProvider.notifier).set(false);

    expect(StorageService.getUnlockAll(), isFalse);
  });
}
