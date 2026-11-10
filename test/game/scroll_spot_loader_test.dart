// The `scroll_spot` object of a boss arena map: read into LoadedLevel.scrollSpots, kept apart
// from the minion spots, and never left over as an ordinary entity. A small inline map, not
// the real assets, so it holds whatever the arenas look like.
import 'package:chronoquest/game/level_loader.dart';
import 'package:flutter_test/flutter_test.dart';

String _tmx(String objects) => '''<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.10.2" orientation="orthogonal" renderorder="right-down" width="4" height="3" tilewidth="24" tileheight="24" infinite="0">
 <layer id="1" name="ground" width="4" height="3" offsety="12">
  <data encoding="csv">
0,0,0,0,
0,0,0,0,
1,1,1,1
</data>
 </layer>
 <objectgroup id="2" name="entities">
  <object id="1" name="start" type="spawn" x="24" y="60"/>
  <object id="2" name="boss" type="boss" x="48" y="60"/>
$objects
 </objectgroup>
</map>''';

void main() {
  test(
      'scroll_spot objects are read into scrollSpots, left to right, apart from minion spots',
      () {
    final level = LevelLoader.parse(_tmx('''
  <object id="3" type="minion_spawn" x="30" y="60"/>
  <object id="4" type="scroll_spot" x="900" y="444"/>
  <object id="5" type="scroll_spot" x="120" y="444.5"/>
  <object id="6" type="minion_spawn" x="10" y="60"/>
'''));
    expect(level.scrollSpots, [(x: 120.0, y: 444.5), (x: 900.0, y: 444.0)]);
    expect(level.minionSpawns, [(x: 10.0, y: 60.0), (x: 30.0, y: 60.0)]);
    expect(level.isArena, isTrue);
    expect(
        level.entities
            .where((e) => e.type == 'scroll_spot' || e.type == 'minion_spawn'),
        isEmpty,
        reason: 'spots are not ordinary entities');
  });

  test('a map without scroll spots has none, and keeps its minion spots', () {
    final level = LevelLoader.parse(_tmx('''
  <object id="3" type="minion_spawn" x="30" y="60"/>
'''));
    expect(level.scrollSpots, isEmpty);
    expect(level.minionSpawns, hasLength(1));
  });
}
