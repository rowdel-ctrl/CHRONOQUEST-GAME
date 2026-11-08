// The order of the heroes on the hero screen: the free ones first, then the others from the
// cheapest to the dearest.
import 'package:chronoquest/core/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the free heroes come first, then the rest by price', () {
    final costs = allCharacters.map((c) => c.unlockCost).toList();
    final firstPaid = costs.indexWhere((c) => c > 0);
    expect(firstPaid, 2, reason: 'Juan and Maria are the two free ones');
    expect(costs.take(firstPaid).every((c) => c == 0), isTrue);
    final paid = costs.skip(firstPaid).toList();
    expect([...paid]..sort(), paid, reason: 'cheapest to dearest');
  });

  test('the order is Juan, Maria, Lapu-Lapu, Bonifacio, Del Pilar, Maria Clara, Luna, Rizal', () {
    expect(allCharacters.map((c) => c.id).toList(),
        ['boy', 'girl', 'lapu', 'bonifacio', 'delpilar', 'mariaclara', 'luna', 'rizal']);
  });

  test('looking a hero up by id does not depend on the order', () {
    for (final c in allCharacters) {
      expect(getCharacterById(c.id).id, c.id);
    }
  });
}
