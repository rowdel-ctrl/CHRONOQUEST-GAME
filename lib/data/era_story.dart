/// The background of each era, cut into short events for the history screen.
///
/// Every fact here comes from that era's `historicalText` in `constants.dart`;
/// the paragraph is only split up, nothing is added. `**word**` marks the words
/// shown in bold. A beat's [label] is a year when the text gives one, otherwise
/// a short topic word. A timeline node has a [top] year only when the text
/// gives one.
class StoryBeat {
  final String label;
  final String text;
  const StoryBeat(this.label, this.text);
}

class TimelineNode {
  final String top;
  final String name;
  const TimelineNode(this.top, this.name);
}

class EraStory {
  final List<StoryBeat> beats;
  final List<TimelineNode> timeline;
  const EraStory({required this.beats, required this.timeline});
}

const Map<String, EraStory> eraStories = {
  'pre-colonial': EraStory(
    beats: [
      StoryBeat('BARANGAY',
          'Ang mga Pilipino ay nabuhay sa **barangay**, maliit na komunidad na pinamumunuan ng isang **datu**.'),
      StoryBeat('KALAKALAN',
          'Mahusay silang mangangalakal at nakipagkalakalan sa **China**, **India**, at iba pang bansa sa Asya.'),
      StoryBeat('SULAT',
          'Gumamit sila ng **baybayin**, isang orihinal na sistema ng pagsulat ng mga Pilipino.'),
      StoryBeat('1521',
          'Sa **Labanan sa Mactan**, ipinagtanggol ni **Datu Lapu-Lapu** ang kanyang lupain.'),
    ],
    timeline: [
      TimelineNode('', 'Barangay'),
      TimelineNode('', 'Kalakalan'),
      TimelineNode('', 'Baybayin'),
      TimelineNode('1521', 'Mactan'),
    ],
  ),
  'spanish': EraStory(
    beats: [
      StoryBeat('1565',
          'Dumating si **Miguel Lopez de Legazpi** at nagsimula ang pananakop ng Espanya.'),
      StoryBeat('300+ TAON',
          'Itinayo ang **Intramuros** sa Maynila. Kinontrol ng Espanya ang relihiyon, kalakalan, at pamahalaan.'),
      StoryBeat('LUPAIN',
          'Ang **encomienda** ay nagbigay ng lupain sa mga Espanyol.'),
      StoryBeat('1896',
          'Naglunsad ng mga rebolusyon ang mga Pilipino, mula sa **Dagohoy Rebellion** hanggang sa **Himagsikan ng 1896** na pinamunuan ni **Andres Bonifacio** at ng **Katipunan**.'),
    ],
    timeline: [
      TimelineNode('1565', 'Legazpi'),
      TimelineNode('', 'Intramuros'),
      TimelineNode('', 'Encomienda'),
      TimelineNode('', 'Dagohoy'),
      TimelineNode('1896', 'Himagsikan'),
    ],
  ),
  'nationalism': EraStory(
    beats: [
      StoryBeat('1872',
          'Pinatay ang **GOMBURZA**, sina Padre **Gomez**, **Burgos**, at **Zamora**. Nagpaalab ito sa damdaming makabayan.'),
      StoryBeat('PROPAGANDA',
          'Itinatag ng mga ilustrado tulad nina **Rizal**, **del Pilar**, at **Lopez Jaena** ang **Propaganda Movement** at ang pahayagang **La Solidaridad** upang hingin ang reporma.'),
      StoryBeat('NOBELA',
          'Isinulat ni Rizal ang **Noli Me Tangere** at **El Filibusterismo** upang ilantad ang kaapihan sa ilalim ng Espanya.'),
      StoryBeat('1892', 'Itinatag ni Rizal ang **La Liga Filipina**.'),
    ],
    timeline: [
      TimelineNode('1872', 'GOMBURZA'),
      TimelineNode('', 'Propaganda'),
      TimelineNode('', 'Noli at Fili'),
      TimelineNode('1892', 'La Liga'),
    ],
  ),
  'american': EraStory(
    beats: [
      StoryBeat('1898',
          'Pagkatapos ng **Digmaang Espanyol-Amerikano**, inilipat ang Pilipinas sa **Estados Unidos**.'),
      StoryBeat('EDUKASYON',
          'Itinatag ng mga Amerikano ang **pampublikong edukasyon** at nagpadala ng **Thomasites**, mga gurong Amerikano.'),
      StoryBeat('DIGMAAN',
          'Naglunsad ng **Philippine-American War** na nagkahalaga ng maraming buhay ng Pilipino.'),
      StoryBeat('1935 - 1946',
          'Naitatag ang **Commonwealth** noong 1935 kay **Manuel Quezon** bilang unang Pangulo. Noong **Hulyo 4, 1946**, nakamit ang kalayaan.'),
    ],
    timeline: [
      TimelineNode('1898', 'Amerikano'),
      TimelineNode('', 'Thomasites'),
      TimelineNode('', 'Digmaan'),
      TimelineNode('1935', 'Commonwealth'),
      TimelineNode('1946', 'Kalayaan'),
    ],
  ),
  'ww2': EraStory(
    beats: [
      StoryBeat('1941',
          'Noong **Disyembre 8, 1941**, sinalakay ng Hapon ang Pilipinas.'),
      StoryBeat('1942',
          'Naganap ang malupit na **Bataan Death March** noong Abril 1942.'),
      StoryBeat('GERILYA',
          'Naghirap ang mga Pilipino sa ilalim ng Hapon. Nabuo ang mga **gerilya** na lumaban, kabilang ang **Hukbalahap**.'),
      StoryBeat('1944 - 1945',
          'Bumalik si **General Douglas MacArthur** noong Oktubre 1944. Ang **Labanan ng Maynila** noong 1945 ay isa sa pinaka-mapanirang labanan sa lungsod sa buong Ikalawang Digmaang Pandaigdig.'),
    ],
    timeline: [
      TimelineNode('1941', 'Pagsalakay'),
      TimelineNode('1942', 'Bataan'),
      TimelineNode('', 'Gerilya'),
      TimelineNode('1944', 'MacArthur'),
      TimelineNode('1945', 'Maynila'),
    ],
  ),
  'modern': EraStory(
    beats: [
      StoryBeat('1946',
          'Noong **Hulyo 4, 1946**, opisyal na naging malaya ang Pilipinas.'),
      StoryBeat('1972 - 1986',
          'Hinarap ng bansa ang maraming pagsubok, mula sa **Marcos diktadura**.'),
      StoryBeat('1986',
          'Ang **People Power Revolution** ang nagluklok kay **Corazon Aquino** bilang Pangulo. Ang **EDSA Revolution** ay naging simbolo ng kapangyarihan ng mamamayan sa buong mundo.'),
      StoryBeat('NGAYON',
          'Patuloy na lumalago ang Pilipinas bilang **demokratikong bansa** na nagtataguyod ng kalayaan, katarungan, at pagkakapantay-pantay.'),
    ],
    timeline: [
      TimelineNode('1946', 'Kalayaan'),
      TimelineNode('1972', 'Diktadura'),
      TimelineNode('1986', 'EDSA'),
      TimelineNode('', 'Demokrasya'),
    ],
  ),
};
