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
      StoryBeat('KATIPUNAN',
          'Noong 1892, itinatag ni **Andres Bonifacio** ang **Katipunan**, ang lihim na samahan para sa kalayaan. Ang **Kartilya ng Katipunan** ay gabay ng mga kasapi, isinulat ni **Emilio Jacinto**.'),
      StoryBeat('1896',
          'Noong **Agosto 1896**, nagtipon ang mga Katipunero sa **Pugad Lawin** at pinunit ang kanilang **sedula**. Noong **Disyembre 30, 1896**, binitay si **Dr. Jose Rizal** sa Bagumbayan.'),
      StoryBeat('BUNGA',
          'Noong **Marso 1897**, nagpulong ang mga rebolusyonaryo sa **Tejeros**. Nahalal si **Emilio Aguinaldo** na Pangulo, pero hindi tinanggap ni Bonifacio ang resulta. Noong **Mayo 1897**, inaresto at pinatay si **Andres Bonifacio**. Noong **Disyembre 1897**, pumirma sila sa **Kasunduan sa Biak-na-Bato**, at napatapon sa Hong Kong sina Aguinaldo.'),
      StoryBeat('1898',
          'Noong **Hunyo 12, 1898**, ipinahayag ang kasarinlan sa Kawit, Cavite. Binasa ni **Ambrosio Rianzares Bautista** ang Acta. Noong **Enero 23, 1899**, pinasinayaan ang **Unang Republika** sa Malolos, at si **Emilio Aguinaldo** ang naging unang Pangulo.'),
      StoryBeat('KABABAIHAN',
          'Maraming babae ang tumulong sa himagsikan. Si **Gregoria de Jesus**, asawa ni Bonifacio, ay kilala bilang **Lakambini** ng Katipunan. Si **Marcela Agoncillo** at ang kanyang mga kasama ay tumahi ng **unang watawat** sa Hong Kong. Si **Teresa Magbanua** ay tinawag na **Joan of Arc ng Visayas**.'),
      StoryBeat('IMPERYALISMO',
          'Ang **imperyalismo** ay pagpapalawak ng kapangyarihan ng isang malakas na bansa sa ibang bansa, para sa yaman at kapangyarihan. Ang madalas na dahilan ay tatlong G: **Gold, Glory at God**. Ginamit ng mga Amerikano ang **Manifest Destiny** at **White Man\'s Burden** para bigyang-katwiran ito.'),
      StoryBeat('DIGMAAN',
          'Noong **Disyembre 10, 1898**, nilagdaan ang **Kasunduan sa Paris**, at ipinasa ng Espanya ang Pilipinas sa Amerika sa halagang **\$20 milyon**. Noong 1899, sumiklab ang **Digmaang Pilipino-Amerikano**. Noong **Disyembre 1899**, namatay si **Gregorio del Pilar** sa **Tirad Pass** habang tinatakpan ang pag-atras ni Aguinaldo. Noong **Abril 1902**, sumuko si **Heneral Miguel Malvar**, at noong **Hulyo 4, 1902**, idineklara ng Amerika na tapos na ang digmaan.'),
      StoryBeat('PAMAMARAAN',
          'Noong **Disyembre 21, 1898**, inilabas ni Pangulong **McKinley** ang **Benevolent Assimilation**, ang tinawag nilang mapagkawanggawang pagsasanib. Noong 1901, dumating ang mga gurong **Thomasites**, at ginawang midyum ng pagtuturo ang **Ingles**. Ipinagbawal din ng **Batas Sedisyon** ng 1901 ang paghihimagsik laban sa pamahalaan.'),
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
      StoryBeat('KAPULUNGAN',
          'Noong **1907**, nagkaroon ng unang **halal na kapulungan** ng mga Pilipino, ang Philippine Assembly. Noong **1916**, ipinangako ng **Jones Law** ang kalayaan at nagtatag ng Senado at Kapulungan ng mga Kinatawan. Sa ilalim ng **Filipinization** ni Gobernador-Heneral Harrison, mas maraming posisyon ang ibinigay sa mga Pilipino.'),
      StoryBeat('KOMONWELT',
          'Noong **1922**, nagpunta sa Amerika ang misyong **OsRox** nina Osmeña at Roxas para humingi ng kalayaan. Noong **1934**, ipinasa ng Amerika ang **Tydings-McDuffie Act**, na nagtakda ng sampung taong transisyon. Noong **Nobyembre 15, 1935**, pinasinayaan ang **Komonwelt**, at si **Manuel Quezon** ang unang Pangulo. Noong 1937, nakaboto na ang mga kababaihan, at ginawang batayan ng pambansang wika ang Tagalog.'),
      StoryBeat('1941',
          'Noong **Disyembre 8, 1941**, sinalakay ng Hapon ang Pilipinas. Noong **Abril 1942**, naganap ang malupit na **Bataan Death March**. Bago umalis sa Pilipinas noong 1942, nangako si **General Douglas MacArthur** ng pagbabalik: Babalik ako.'),
      StoryBeat('PAMAHALAANG HAPON',
          'Layunin ng Hapon na gamitin ang Pilipinas sa digmaan. Noong **Oktubre 14, 1943**, itinatag nila ang **Ikalawang Republika** sa ilalim ni **Jose P. Laurel**. Ang **KALIBAPI** ang nag-iisang partido, at ang **Makapili** ay grupong pumanig sa Hapon.'),
      StoryBeat('GERILYA',
          'Nabuo ang mga **gerilya** na lumaban sa Hapon, kabilang ang **Hukbalahap**. Ang **Kempeitai** ang militar na pulis ng Hapon na nagpahirap sa mga lumalaban. Si **Chief Justice Jose Abad Santos** ay pinatay noong **Mayo 1942** dahil tumangging makipagtulungan sa Hapon. Si **Josefa Llanes Escoda**, tagapagtatag ng **Girl Scouts of the Philippines**, ay ikinulong sa Fort Santiago at hindi na nakita pagkatapos ng Enero 1945.'),
      StoryBeat('1946',
          'Noong **Hulyo 4, 1946**, opisyal na nakamit ng Pilipinas ang kalayaan. Nasira ang mga bayan at ang Maynila pagkatapos ng digmaan, at si **Manuel Roxas** ang unang Pangulo ng Ikatlong Republika. Lumakas ang **Huk** dahil sa kahirapan, at tinawag na **Kampeon ng Masa** si **Ramon Magsaysay** dahil sa pagtugon dito.'),
      StoryBeat('NEOKOLONYALISMO',
          'Noong **1946**, ipinasa ang **Bell Trade Act**, na nagbigay sa mga Amerikano ng **parity rights**. Noong **1947**, pumirma ang dalawang bansa ng **Military Bases Agreement**, na may 99 taong pag-upa ng mga base. Noong **1991**, tinanggihan ng Senado ang bagong kasunduan, at umalis ang mga base noong 1992.'),
      StoryBeat('KULTURA',
          'Ang **colonial mentality** ay ugaling mas pinapahalagahan ang banyaga kaysa sa sarili. Sinabi ni **Renato Constantino** sa aklat na The Miseducation of the Filipino na may mali sa edukasyong kolonyal. Itinatag ang **Cultural Center of the Philippines** noong 1966 para ipakita ang sariling sining.'),
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
      StoryBeat('1972',
          'Noong **Setyembre 21, 1972**, pinirmahan ni **Ferdinand Marcos** ang **Proklamasyon 1081**, ang Batas Militar. Isinara ang mga pahayagan, radyo, at telebisyon, at maraming paglabag sa karapatang pantao. Ang mga malapit kay Marcos ay yumaman sa **crony capitalism**. Inalis ang pormal na Batas Militar noong **Enero 17, 1981**, pero nanatili ang kapangyarihan ni Marcos. Noong **Agosto 21, 1983**, pinatay si **Ninoy Aquino** pagdating niya sa paliparan ng Maynila.'),
      StoryBeat('EDSA',
          'Noong **Pebrero 7, 1986**, nagkaroon ng **snap election** laban kay Marcos at **Cory Aquino**. Noong **Pebrero 22, 1986**, kumalas sina **Juan Ponce Enrile** at **Fidel Ramos** kay Marcos, at nanawagan si **Cardinal Sin** sa Radio Veritas na pumunta sa EDSA. Mapayapang nagtipon ang mga tao hanggang **Pebrero 25**, nang umalis si Marcos. Ang **EDSA Revolution** ay naging simbolo ng kapangyarihan ng mamamayan sa buong mundo.'),
      StoryBeat('KONSTITUSYON',
          'Pagkatapos ng EDSA, ipinatupad ni Aquino ang pansamantalang **Freedom Constitution**. Itinatag ang **PCGG** para habulin ang yamang ninakaw sa panahon ni Marcos. Noong **Pebrero 2, 1987**, niratipikahan ang **Saligang Batas ng 1987**, na may anim na taong termino ng Pangulo at walang reelection.'),
      StoryBeat('POLITIKA',
          'Noong **Enero 2001**, nagkaroon ng **EDSA II** na nagpatalsik kay Joseph Estrada. Noong **2013**, sumabog ang **Pork Barrel Scam**, isang malaking iskandalo sa pondo ng gobyerno. Noong **Hulyo 12, 2016**, nanalo ang Pilipinas sa Permanent Court of Arbitration tungkol sa West Philippine Sea. Noong **2018**, ipinasa ang **Bangsamoro Organic Law**.'),
      StoryBeat('EKONOMIYA',
          'Ang **Philippines 2000** ni Pangulong **Fidel V. Ramos** ay plano para sa pag-unlad noong 1990s. Lumago ang **BPO industry** mula 2000s. Noong **2008**, inilunsad ang **4Ps**, ang tulong para sa mahihirap na pamilya. Noong **2018**, ipinatupad ang **TRAIN Law** sa buwis. Noong **Nobyembre 8, 2013**, sinalanta ng **Yolanda (Haiyan)** ang bansa, at noong 2020, pinahirapan ng COVID-19 ang ekonomiya. Maraming Pilipino ang nagtatrabaho sa ibang bansa bilang **OFW**.'),
    ],
    timeline: [
      TimelineNode('1946', 'Kalayaan'),
      TimelineNode('1972', 'Diktadura'),
      TimelineNode('1986', 'EDSA'),
      TimelineNode('', 'Demokrasya'),
    ],
  ),
};
