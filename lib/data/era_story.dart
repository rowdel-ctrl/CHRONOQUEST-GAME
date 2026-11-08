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
      StoryBeat('KAUGALIAN',
          'Ang bawat **barangay** ay may sariling kaugalian, tradisyon, at sistema ng pamahalaan.'),
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
      StoryBeat('INTRAMUROS',
          'Itinayo nila ang **Intramuros** sa Maynila bilang sentro ng kanilang kapangyarihan.'),
      StoryBeat('300+ TAON',
          'Sa loob ng mahigit tatlong daang taon, kinontrol ng Espanya ang relihiyon, kalakalan, at pamahalaan ng bansa.'),
      StoryBeat('LUPAIN',
          'Ang sistemang **encomienda** ay nagbigay ng lupain sa mga Espanyol.'),
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
      StoryBeat('IKA-19 NA SIGLO',
          'Noong huling bahagi ng ika-19 na siglo, sumibol ang damdaming **nasyonalista** sa mga Pilipino.'),
      StoryBeat('1872',
          'Pinatay ang **GOMBURZA**, sina Padre **Gomez**, **Burgos**, at **Zamora**. Nagpaalab ito sa damdaming makabayan.'),
      StoryBeat('PROPAGANDA',
          'Itinatag ang **Propaganda Movement** ng mga ilustrado tulad nina **Jose Rizal**, **Marcelo H. del Pilar**, at **Graciano Lopez Jaena**, na naglathala ng pahayagang **La Solidaridad** sa Espanya upang hingin ang reporma.'),
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
          'Itinatag ng mga Amerikano ang sistema ng **edukasyong pampubliko** at nagpadala ng **Thomasites**, mga guro mula Amerika.'),
      StoryBeat('DIGMAAN',
          'Nagtagal ang pananakop ng Amerika at naglunsad ng **Philippine-American War** na nagkahalaga ng maraming buhay ng Pilipino.'),
      StoryBeat('1935',
          'Naitatag ang **Commonwealth** ng Pilipinas noong 1935, na may **Manuel Quezon** bilang unang Pangulo.'),
      StoryBeat('1946',
          'Noong **Hulyo 4, 1946**, opisyal na nakamit ng Pilipinas ang kalayaan.'),
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
          'Sa ilalim ng pananakop ng Hapon, naghirap ang mga Pilipino. Nabuo ang mga **gerilya** na lumaban sa Hapon, kabilang ang **Hukbalahap**.'),
      StoryBeat('1944',
          'Noong Oktubre 1944, bumalik si **General Douglas MacArthur** at nagsimula ang Labanan para sa Pilipinas.'),
      StoryBeat('1945',
          'Ang **Labanan ng Maynila** noong 1945 ay isa sa pinaka-mapanirang labanan sa lungsod sa buong Ikalawang Digmaang Pandaigdig.'),
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
          'Sa mga sumunod na dekada, hinarap ng bansa ang maraming pagsubok, mula sa **Marcos diktadura** (1972–1986).'),
      StoryBeat('1986',
          'Ang **People Power Revolution** ang nagluklok kay **Corazon Aquino** bilang Pangulo noong 1986.'),
      StoryBeat('EDSA',
          'Ang **EDSA Revolution** ay naging simbolo ng kapangyarihan ng mamamayan sa buong mundo.'),
      StoryBeat('NGAYON',
          'Patuloy na lumalago ang Pilipinas bilang isang **demokratikong bansa** na nagtataguyod ng kalayaan, katarungan, at pagkakapantay-pantay para sa lahat ng Pilipino.'),
    ],
    timeline: [
      TimelineNode('1946', 'Kalayaan'),
      TimelineNode('1972', 'Diktadura'),
      TimelineNode('1986', 'EDSA'),
      TimelineNode('', 'Demokrasya'),
    ],
  ),
};
