/// One short history fact for the "Alam mo ba?" line on the first screen.
///
/// None of these is new: each is one event from [eraStories] (the text of the
/// history screen), cut short. [label] is that event's label there and [proof] is
/// the sentence it comes from (without the bold marks), so a test can check that a
/// fact never drifts from what the game teaches.
class LoginFact {
  final String text;
  final String label;
  final String proof;
  const LoginFact(this.text, {required this.label, required this.proof});
}

const List<LoginFact> loginFacts = [
  LoginFact(
    'Noong 1521, ipinagtanggol ni Datu Lapu-Lapu ang Mactan.',
    label: '1521',
    proof: 'ipinagtanggol ni Datu Lapu-Lapu ang kanyang lupain',
  ),
  LoginFact(
    'Ang baybayin ay orihinal na sistema ng pagsulat ng mga Pilipino.',
    label: 'SULAT',
    proof: 'baybayin, isang orihinal na sistema ng pagsulat ng mga Pilipino',
  ),
  LoginFact(
    'Noong 1565, dumating si Legazpi at nagsimula ang pananakop ng Espanya.',
    label: '1565',
    proof:
        'Dumating si Miguel Lopez de Legazpi at nagsimula ang pananakop ng Espanya',
  ),
  LoginFact(
    'Noong 1872, pinatay ang GOMBURZA: sina Gomez, Burgos, at Zamora.',
    label: '1872',
    proof: 'Pinatay ang GOMBURZA, sina Padre Gomez, Burgos, at Zamora',
  ),
  LoginFact(
    'Isinulat ni Rizal ang Noli Me Tangere at El Filibusterismo.',
    label: 'NOBELA',
    proof: 'Isinulat ni Rizal ang Noli Me Tangere at El Filibusterismo',
  ),
  LoginFact(
    'Noong Disyembre 8, 1941, sinalakay ng Hapon ang Pilipinas.',
    label: '1941',
    proof: 'Noong Disyembre 8, 1941, sinalakay ng Hapon ang Pilipinas',
  ),
  LoginFact(
    'Noong Hulyo 4, 1946, nakamit ng Pilipinas ang kalayaan.',
    label: '1935 - 1946',
    proof: 'Noong Hulyo 4, 1946, nakamit ang kalayaan',
  ),
  LoginFact(
    'Ang EDSA Revolution ay naging simbolo ng kapangyarihan ng mamamayan.',
    label: '1986',
    proof:
        'Ang EDSA Revolution ay naging simbolo ng kapangyarihan ng mamamayan',
  ),
];
