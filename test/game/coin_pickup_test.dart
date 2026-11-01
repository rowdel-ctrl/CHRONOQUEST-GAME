// Every coin goes into the wallet the moment it is picked up, and is saved on the
// phone, so leaving a level from the pause menu (or closing the app) loses none.
import 'dart:io';

import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/services/server_clock.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = Directory.systemTemp.createTempSync('chronoquest_coin_pickup_test_').path;

  setUpAll(() async {
    Hive.init(dir);
    await Hive.openBox('chronoquest');
  });

  tearDownAll(() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await Hive.close();
    try {
      Directory(dir).deleteSync(recursive: true);
    } catch (_) {}
  });

  test('each coin picked up tells the game screen, once', () {
    final game = ChronoGame();
    var told = 0;
    game.onCoinCollected = () => told++;

    game.collectCoin();
    game.collectCoin();
    game.collectCoin();

    expect(told, 3);
    expect(game.playerCoins, 3, reason: "the level's own count still counts up too");
  });

  test('wired to the wallet, the coins are there at once and survive a restart, with no level end',
      () {
    final wallet = GameNotifier(clock: ServerClock.fixed(DateTime.utc(2020, 1, 1, 12)))
      ..loadWallet('pick1');
    final game = ChronoGame()..onCoinCollected = () => wallet.addCoins(1);

    for (var i = 0; i < 12; i++) {
      game.collectCoin();
    }
    expect(wallet.state.coins, 12);
    // The student quits from the pause menu: nothing more happens. A new session
    // on the same phone still has them.
    final later = GameNotifier(clock: ServerClock.fixed(DateTime.utc(2020, 1, 1, 12)))
      ..loadWallet('pick1');
    expect(later.state.coins, 12);
    expect(StorageService.getWallet('pick1')!['coins'], 12);
  });
}
