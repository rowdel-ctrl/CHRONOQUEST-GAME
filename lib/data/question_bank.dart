import '../models/question.dart';

class QuestionBank {
  static final Map<String, Map<int, List<Question>>> _bank = {
    // ─── 1. SINAUNANG PANAHON (PRE-COLONIAL) - GRADE 4 & 5 MELC ───────────────
    'pre-colonial': {
      1: [
        Question(
          id: 'pre_1_1',
          era: 'pre-colonial',
          gradeLevel: 'grade4',
          level: 1,
          questionText: 'Ano ang tawag sa teoryang nagsasabing ang mga sinaunang Pilipino ay nagmula sa Timog-Silangang Asya gamit ang mga bangka?',
          options: const [
            QuestionOption(label: 'A', text: 'Teoryang Austronesian'),
            QuestionOption(label: 'B', text: 'Teoryang Land Bridges'),
            QuestionOption(label: 'C', text: 'Teoryang Continental Drift'),
            QuestionOption(label: 'D', text: 'Teoryang Evolution'),
          ],
          correctAnswer: 'A',
          explanation: 'Ayon kay Peter Bellwood, ang mga Austronesian ay nagmula sa Timog Tsina at Taiwan bago nakarating sa Pilipinas.',
        ),
      ],
      2: [
        Question(
          id: 'pre_2_1',
          era: 'pre-colonial',
          gradeLevel: 'grade4',
          level: 2,
          questionText: 'Sino ang nagsisilbing pinuno at tagapagtanggol ng isang sinaunang barangay?',
          options: const [
            QuestionOption(label: 'A', text: 'Datu'),
            QuestionOption(label: 'B', text: 'Babaylan'),
            QuestionOption(label: 'C', text: 'Alipin'),
            QuestionOption(label: 'D', text: 'Maharlika'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang Datu ang pinuno ng barangay na namamahala sa lipunan, batas, at pagtatanggol.',
        ),
      ],
      3: [
        Question(
          id: 'pre_3_1',
          era: 'pre-colonial',
          gradeLevel: 'grade4',
          level: 3,
          questionText: 'Sino ang itinuturing na pinakamataas na uri sa lipunan ng mga sinaunang Tagalog?',
          options: const [
            QuestionOption(label: 'A', text: 'Maginoo / Maharlika'),
            QuestionOption(label: 'B', text: 'Timawa'),
            QuestionOption(label: 'C', text: 'Aliping Namamahay'),
            QuestionOption(label: 'D', text: 'Aliping Saguiguilid'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang Maginoo o Maharlika ang pinakamataas na antas kung saan nagmumula ang Datu.',
        ),
      ],
      4: [
        Question(
          id: 'pre_4_1',
          era: 'pre-colonial',
          gradeLevel: 'grade4',
          level: 4,
          questionText: 'Ano ang tawag sa katutubong sistema ng pagsulat ng mga sinaunang Pilipino?',
          options: const [
            QuestionOption(label: 'A', text: 'Baybayin'),
            QuestionOption(label: 'B', text: 'Abakada'),
            QuestionOption(label: 'C', text: 'Cuneiform'),
            QuestionOption(label: 'D', text: 'Hieroglyphics'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang Baybayin ay ang sinaunang alpabeto ng mga Pilipino bago dumating ang mga Espanyol.',
        ),
      ],
      5: [
        Question(
          id: 'pre_5_1',
          era: 'pre-colonial',
          gradeLevel: 'grade5',
          level: 5,
          questionText: 'Anong sistema ng kalakalan ang ginagamit ng mga sinaunang Pilipino bago nauso ang pera?',
          options: const [
            QuestionOption(label: 'A', text: 'Barter'),
            QuestionOption(label: 'B', text: 'Galleon Trade'),
            QuestionOption(label: 'C', text: 'Cash Transfer'),
            QuestionOption(label: 'D', text: 'Tributo'),
          ],
          correctAnswer: 'A',
          explanation: 'Barter ang tawag sa direktang pagpapalit ng produkto sa iba pang produkto.',
        ),
      ],
      6: [
        Question(
          id: 'pre_6_1',
          era: 'pre-colonial',
          gradeLevel: 'grade5',
          level: 6,
          questionText: 'Sino ang ispiritwal na pinuno at manggagamot sa sinaunang lipunang Pilipino?',
          options: const [
            QuestionOption(label: 'A', text: 'Babaylan / Katalonan'),
            QuestionOption(label: 'B', text: 'Datu'),
            QuestionOption(label: 'C', text: 'Pari'),
            QuestionOption(label: 'D', text: 'Umalohokan'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang Babaylan (sa Visayas) o Katalonan (sa Tagalog) ay ang lider pang-espiritwal at manggagamot.',
        ),
      ],
      7: [
        Question(
          id: 'pre_7_1',
          era: 'pre-colonial',
          gradeLevel: 'grade4',
          level: 7,
          questionText: 'Ano ang tawag sa tagapagbalita ng mga bagong batas sa buong barangay?',
          options: const [
            QuestionOption(label: 'A', text: 'Umalohokan'),
            QuestionOption(label: 'B', text: 'Panday'),
            QuestionOption(label: 'C', text: 'Timawa'),
            QuestionOption(label: 'D', text: 'Gobernadorcillo'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang Umalohokan ay gumagamit ng kubing o tambuli upang tawagin ang pansin ng mga mamamayan.',
        ),
      ],
      8: [
        Question(
          id: 'pre_8_1',
          era: 'pre-colonial',
          gradeLevel: 'grade5',
          level: 8,
          questionText: 'Ano ang pananampalataya ng mga sinaunang Pilipino sa mga espiritu ng kalikasan at mga anito?',
          options: const [
            QuestionOption(label: 'A', text: 'Animismo'),
            QuestionOption(label: 'B', text: 'Kristiyanismo'),
            QuestionOption(label: 'C', text: 'Islam'),
            QuestionOption(label: 'D', text: 'Budismo'),
          ],
          correctAnswer: 'A',
          explanation: 'Animismo ang paniniwala na ang mga puno, ilog, at bundok ay may mga espiritu o anito.',
        ),
      ],
      9: [
        Question(
          id: 'pre_9_1',
          era: 'pre-colonial',
          gradeLevel: 'grade5',
          level: 9,
          questionText: 'Kailan naganap ang tanyag na Labanan sa Mactan kung saan natalo ang hukbo ni Magellan?',
          options: const [
            QuestionOption(label: 'A', text: 'Abril 27, 1521'),
            QuestionOption(label: 'B', text: 'Marso 16, 1521'),
            QuestionOption(label: 'C', text: 'Hunyo 12, 1898'),
            QuestionOption(label: 'D', text: 'Disyembre 25, 1521'),
          ],
          correctAnswer: 'A',
          explanation: 'Noong Abril 27, 1521, pinunuan ni Lapu-Lapu ang pakikipaglaban kay Ferdinand Magellan sa Mactan.',
        ),
      ],
      10: [
        Question(
          id: 'pre_10_1',
          era: 'pre-colonial',
          gradeLevel: 'grade4',
          level: 10,
          questionText: 'Sino ang kauna-unahang bayaning Pilipino na nagtanggol sa kalayaan laban sa dayuhang mananakop?',
          options: const [
            QuestionOption(label: 'A', text: 'Datu Lapu-Lapu'),
            QuestionOption(label: 'B', text: 'Rajah Sulayman'),
            QuestionOption(label: 'C', text: 'Datu Zula'),
            QuestionOption(label: 'D', text: 'Jose Rizal'),
          ],
          correctAnswer: 'A',
          explanation: 'Si Lapu-Lapu ang pinuno ng Mactan na tumangging magpasakop sa mga Espanyol.',
        ),
      ],
    },

    // ─── 2. PANAHON NG KASTILA (SPANISH COLONIAL) - GRADE 5 MELC ──────────────
    'spanish': {
      1: [
        Question(
          id: 'spa_1_1',
          era: 'spanish',
          gradeLevel: 'grade5',
          level: 1,
          questionText: 'Sino ang manlalakbay na Espanyol na nakarating sa Homonhon, Pilipinas noong Marso 1521?',
          options: const [
            QuestionOption(label: 'A', text: 'Ferdinand Magellan'),
            QuestionOption(label: 'B', text: 'Miguel Lopez de Legazpi'),
            QuestionOption(label: 'C', text: 'Ruy Lopez de Villalobos'),
            QuestionOption(label: 'D', text: 'Juan de Salcedo'),
          ],
          correctAnswer: 'A',
          explanation: 'Si Magellan ang namuno sa ekspedisyong Espanyol na unang nakarating sa Kapuluan.',
        ),
      ],
      2: [
        Question(
          id: 'spa_2_1',
          era: 'spanish',
          gradeLevel: 'grade5',
          level: 2,
          questionText: 'Sino ang unang Gobernador-Heneral ng Espanya na nagtatag ng permanenteng pamayanan sa Cebu noong 1565?',
          options: const [
            QuestionOption(label: 'A', text: 'Miguel Lopez de Legazpi'),
            QuestionOption(label: 'B', text: 'Ferdinand Magellan'),
            QuestionOption(label: 'C', text: 'Jose Basco'),
            QuestionOption(label: 'D', text: 'Narciso Claveria'),
          ],
          correctAnswer: 'A',
          explanation: 'Itinatag ni Legazpi ang San Miguel (Cebu) at noong huli ay ginawang kabisera ang Maynila.',
        ),
      ],
      3: [
        Question(
          id: 'spa_3_1',
          era: 'spanish',
          gradeLevel: 'grade5',
          level: 3,
          questionText: 'Ano ang pangunahing layunin ng Espanya sa pananakop sa Pilipinas na kinakatawan ng "3 Gs"?',
          options: const [
            QuestionOption(label: 'A', text: 'God, Gold, and Glory'),
            QuestionOption(label: 'B', text: 'Good, Great, and Grace'),
            QuestionOption(label: 'C', text: 'Growth, Guns, and Government'),
            QuestionOption(label: 'D', text: 'Give, Gain, and Go'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang 3 Gs ay God (Relhiyon), Gold (Kayamanan), at Glory (Kapangyarihan/Karangalan).',
        ),
      ],
      4: [
        Question(
          id: 'spa_4_1',
          era: 'spanish',
          gradeLevel: 'grade5',
          level: 4,
          questionText: 'Ano ang tawag sa pampublikong parusa o buwis na sapilitang ipinapataw sa mga katutubong Pilipino?',
          options: const [
            QuestionOption(label: 'A', text: 'Tributo'),
            QuestionOption(label: 'B', text: 'Bandala'),
            QuestionOption(label: 'C', text: 'Encomienda'),
            QuestionOption(label: 'D', text: 'Polo y Servicios'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang Tributo ay ang buwis sa pananalapi o produkto na ibinibigay sa pamahalaang Espanyol.',
        ),
      ],
      5: [
        Question(
          id: 'spa_5_1',
          era: 'spanish',
          gradeLevel: 'grade5',
          level: 5,
          questionText: 'Ano ang tawag sa sapilitang pagtatrabaho ng mga kalalakihang Pilipino na may edad 16 hanggang 60?',
          options: const [
            QuestionOption(label: 'A', text: 'Polo y Servicios'),
            QuestionOption(label: 'B', text: 'Falla'),
            QuestionOption(label: 'C', text: 'Sambo'),
            QuestionOption(label: 'D', text: 'Galleon Trade'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang Polo y Servicios ay sapilitang paggawa ng mga barko, kalsada, at simbahan sa loob ng 40 araw.',
        ),
      ],
      6: [
        Question(
          id: 'spa_6_1',
          era: 'spanish',
          gradeLevel: 'grade5',
          level: 6,
          questionText: 'Ano ang tawag sa kalakalang nag-uugnay sa Maynila at Acapulco, Mexico?',
          options: const [
            QuestionOption(label: 'A', text: 'Kalakalang Galyon'),
            QuestionOption(label: 'B', text: 'Silk Road'),
            QuestionOption(label: 'C', text: 'Barter System'),
            QuestionOption(label: 'D', text: 'Free Trade'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang Kalakalang Galyon (Galleon Trade) ay tumagal ng higit 250 taon sa pagitan ng Maynila at Mexico.',
        ),
      ],
      7: [
        Question(
          id: 'spa_7_1',
          era: 'spanish',
          gradeLevel: 'grade5',
          level: 7,
          questionText: 'Sino ang Pambansang Bayani na nagsulat ng nobelang Noli Me Tangere at El Filibusterismo?',
          options: const [
            QuestionOption(label: 'A', text: 'Dr. Jose Rizal'),
            QuestionOption(label: 'B', text: 'Andres Bonifacio'),
            QuestionOption(label: 'C', text: 'Marcelo H. del Pilar'),
            QuestionOption(label: 'D', text: 'Apolinario Mabini'),
          ],
          correctAnswer: 'A',
          explanation: 'Ibinunyag ni Dr. Jose Rizal ang pang-aabuso ng mga prayle at Espanyol sa kanyang mga nobela.',
        ),
      ],
      8: [
        Question(
          id: 'spa_8_1',
          era: 'spanish',
          gradeLevel: 'grade5',
          level: 8,
          questionText: 'Ano ang lihim na samahang itinatag ni Andres Bonifacio noong Hulyo 7, 1892?',
          options: const [
            QuestionOption(label: 'A', text: 'Katipunan (KKK)'),
            QuestionOption(label: 'B', text: 'La Liga Filipina'),
            QuestionOption(label: 'C', text: 'Propaganda Movement'),
            QuestionOption(label: 'D', text: 'Confradia de San Jose'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang KKK ay naglayong makamit ang ganap na kalayaan ng Pilipinas sa pamamagitan ng rebolusyon.',
        ),
      ],
      9: [
        Question(
          id: 'spa_9_1',
          era: 'spanish',
          gradeLevel: 'grade5',
          level: 9,
          questionText: 'Ano ang ginawa ng mga Katipunero sa Pugad Lawin bilang simbolo ng pagpunit sa kapangyarihan ng Espanya?',
          options: const [
            QuestionOption(label: 'A', text: 'Pinunit ang kanilang mga Cedula'),
            QuestionOption(label: 'B', text: 'Sinunog ang watawat ng Espanya'),
            QuestionOption(label: 'C', text: 'Itinapon ang mga baril'),
            QuestionOption(label: 'D', text: 'Pinatunog ang mga kampana'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang Sigaw sa Pugad Lawin ay minarkahan ng pagpunit ng cedula bilang simula ng Himagsikan.',
        ),
      ],
      10: [
        Question(
          id: 'spa_10_1',
          era: 'spanish',
          gradeLevel: 'grade5',
          level: 10,
          questionText: 'Kailan idineklara ni Heneral Emilio Aguinaldo ang Kasarinlan ng Pilipinas sa Kawit, Cavite?',
          options: const [
            QuestionOption(label: 'A', text: 'Hunyo 12, 1898'),
            QuestionOption(label: 'B', text: 'Hulyo 4, 1946'),
            QuestionOption(label: 'C', text: 'Nobyembre 30, 1896'),
            QuestionOption(label: 'D', text: 'Disyembre 30, 1896'),
          ],
          correctAnswer: 'A',
          explanation: 'Noong Hunyo 12, 1898, unang itinaas ang watawat ng Pilipinas at pinatugtog ang Lupang Hinirang.',
        ),
      ],
    },

    // ─── 3. PANAHON NG AMERIKANO (AMERICAN PERIOD) - GRADE 5 & 6 MELC ────────
    'american': {
      1: [
        Question(
          id: 'ame_1_1',
          era: 'american',
          gradeLevel: 'grade5',
          level: 1,
          questionText: 'Anong kasunduan ang nilagdaan noong Disyembre 1898 kung saan ipinagbili ng Espanya ang Pilipinas sa Amerika sa halagang \$20 Milyon?',
          options: const [
            QuestionOption(label: 'A', text: 'Kasunduan sa Paris'),
            QuestionOption(label: 'B', text: 'Kasunduan sa Biak-na-Bato'),
            QuestionOption(label: 'C', text: 'Batas Tydings-McDuffie'),
            QuestionOption(label: 'D', text: 'Kasunduang Bates'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang Treaty of Paris (1898) ang pormal na naglipat ng kontrol sa Pilipinas mula Espanya tungo sa US.',
        ),
      ],
      2: [
        Question(
          id: 'ame_2_1',
          era: 'american',
          gradeLevel: 'grade6',
          level: 2,
          questionText: 'Sino ang Unang Pangulo ng Unang Republika ng Pilipinas na namuno sa Digmaang Pilipino-Amerikano?',
          options: const [
            QuestionOption(label: 'A', text: 'Emilio Aguinaldo'),
            QuestionOption(label: 'B', text: 'Manuel L. Quezon'),
            QuestionOption(label: 'C', text: 'Apolinario Mabini'),
            QuestionOption(label: 'D', text: 'Sergio Osmeña'),
          ],
          correctAnswer: 'A',
          explanation: 'Si Heneral Emilio Aguinaldo ang namuno sa Republika ng Malolos laban sa mga Amerikano.',
        ),
      ],
      3: [
        Question(
          id: 'ame_3_1',
          era: 'american',
          gradeLevel: 'grade6',
          level: 3,
          questionText: 'Ano ang tawag sa unang pangkat ng mga gurong Amerikano na dumating sakay ng USS Thomas noong 1901?',
          options: const [
            QuestionOption(label: 'A', text: 'Thomasites'),
            QuestionOption(label: 'B', text: 'Pensions'),
            QuestionOption(label: 'C', text: 'Missionaries'),
            QuestionOption(label: 'D', text: 'Peace Corps'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang mga Thomasites ang nagtatag ng pampublikong sistema ng edukasyon sa buong bansa.',
        ),
      ],
      4: [
        Question(
          id: 'ame_4_1',
          era: 'american',
          gradeLevel: 'grade6',
          level: 4,
          questionText: 'Anong wika ang ginamit bilang pangunahing wikang panturo sa mga paaralan sa ilalim ng pamamahala ng Amerika?',
          options: const [
            QuestionOption(label: 'A', text: 'Ingles'),
            QuestionOption(label: 'B', text: 'Espanyol'),
            QuestionOption(label: 'C', text: 'Tagalog'),
            QuestionOption(label: 'D', text: 'Niponggo'),
          ],
          correctAnswer: 'A',
          explanation: 'Itinuro ng mga Amerikano ang wikang Ingles sa lahat ng pampublikong paaralan.',
        ),
      ],
      5: [
        Question(
          id: 'ame_5_1',
          era: 'american',
          gradeLevel: 'grade6',
          level: 5,
          questionText: 'Ano ang tawag sa transisyonal na pamahalaan na itinatag noong 1935 bilang paghahanda sa ganap na kalayaan?',
          options: const [
            QuestionOption(label: 'A', text: 'Pamahalaang Commonwealth'),
            QuestionOption(label: 'B', text: 'Pamahalaang Miltar'),
            QuestionOption(label: 'C', text: 'Pamahalaang Sibil'),
            QuestionOption(label: 'D', text: 'Ikatlong Republika'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang Commonwealth ng Pilipinas ay may 10-taong probisyon bago ibigay ang ganap na kalayaan.',
        ),
      ],
      6: [
        Question(
          id: 'ame_6_1',
          era: 'american',
          gradeLevel: 'grade6',
          level: 6,
          questionText: 'Sino ang tinaguriang "Ama ng Wikang Pambansa" at naging Unang Pangulo ng Pamahalaang Commonwealth?',
          options: const [
            QuestionOption(label: 'A', text: 'Manuel L. Quezon'),
            QuestionOption(label: 'B', text: 'Jose P. Laurel'),
            QuestionOption(label: 'C', text: 'Sergio Osmeña'),
            QuestionOption(label: 'D', text: 'Diosdado Macapagal'),
          ],
          correctAnswer: 'A',
          explanation: 'Isinulong ni Manuel L. Quezon ang pagkakaroon ng pambansang wika batay sa Tagalog.',
        ),
      ],
      7: [
        Question(
          id: 'ame_7_1',
          era: 'american',
          gradeLevel: 'grade5',
          level: 7,
          questionText: 'Sino ang tinaguriang "Utak ng Rebolusyon" at dakilang paralitiko na naglingkod bilang tagapayo ni Aguinaldo?',
          options: const [
            QuestionOption(label: 'A', text: 'Apolinario Mabini'),
            QuestionOption(label: 'B', text: 'Emilio Jacinto'),
            QuestionOption(label: 'C', text: 'Antonio Luna'),
            QuestionOption(label: 'D', text: 'Juan Luna'),
          ],
          correctAnswer: 'A',
          explanation: 'Kahit may kapansanan, si Apolinario Mabini ang sumulat ng maraming pampolitikang konstitusyon.',
        ),
      ],
      8: [
        Question(
          id: 'ame_8_1',
          era: 'american',
          gradeLevel: 'grade6',
          level: 8,
          questionText: 'Sino ang batang heneral na nagbuwis ng buhay sa Labanan sa Pasong Tirad upang makatakas si Aguinaldo?',
          options: const [
            QuestionOption(label: 'A', text: 'Gregorio del Pilar'),
            QuestionOption(label: 'B', text: 'Antonio Luna'),
            QuestionOption(label: 'C', text: 'Macario Sakay'),
            QuestionOption(label: 'D', text: 'Artemio Ricarte'),
          ],
          correctAnswer: 'A',
          explanation: 'Si Gregorio del Pilar ay 24 taong gulang lamang nang maging bayani ng Tirad Pass.',
        ),
      ],
      9: [
        Question(
          id: 'ame_9_1',
          era: 'american',
          gradeLevel: 'grade6',
          level: 9,
          questionText: 'Anong karapatan ang matagumpay na naipaglaban ng mga kababaihang Pilipino noong Plebisito ng 1937?',
          options: const [
            QuestionOption(label: 'A', text: 'Karapatang Bumoto (Suffrage)'),
            QuestionOption(label: 'B', text: 'Karapatang Mag-aral'),
            QuestionOption(label: 'C', text: 'Karapatang Magtrabaho'),
            QuestionOption(label: 'D', text: 'Karapatang Maging Sundalo'),
          ],
          correctAnswer: 'A',
          explanation: 'Noong 1937, bumoto ang higit 447,000 kababaihan pabor sa kanilang karapatang pumili ng pinuno.',
        ),
      ],
      10: [
        Question(
          id: 'ame_10_1',
          era: 'american',
          gradeLevel: 'grade6',
          level: 10,
          questionText: 'Anong batas ang nagkaloob ng pormal na proseso at petsa ng kalayaan ng Pilipinas mula sa Estados Unidos?',
          options: const [
            QuestionOption(label: 'A', text: 'Batas Tydings-McDuffie'),
            QuestionOption(label: 'B', text: 'Batas Hare-Hawes-Cutting'),
            QuestionOption(label: 'C', text: 'Batas Jones'),
            QuestionOption(label: 'D', text: 'Batas Cooper'),
          ],
          correctAnswer: 'A',
          explanation: 'Pinagtibay ng Batas Tydings-McDuffie (1934) ang pagtatag ng Commonwealth at probisyon ng kalayaan.',
        ),
      ],
    },

    // ─── 4. IKALAWANG DIGMAANG PANDAIGDIG (WW2) - GRADE 6 MELC ───────────────
    'ww2': {
      1: [
        Question(
          id: 'ww2_1_1',
          era: 'ww2',
          gradeLevel: 'grade6',
          level: 1,
          questionText: 'Anong bansa sa Asya ang biglang sumalakay sa Pilipinas noong Disyembre 1941?',
          options: const [
            QuestionOption(label: 'A', text: 'Hapon (Japan)'),
            QuestionOption(label: 'B', text: 'Tsina (China)'),
            QuestionOption(label: 'C', text: 'Alemanya (Germany)'),
            QuestionOption(label: 'D', text: 'Espanya (Spain)'),
          ],
          correctAnswer: 'A',
          explanation: 'Sinalakay ng Hapon ang Pearl Harbor at Clark Field noong Disyembre 8, 1941.',
        ),
      ],
      2: [
        Question(
          id: 'ww2_2_1',
          era: 'ww2',
          gradeLevel: 'grade6',
          level: 2,
          questionText: 'Ano ang ginawa ni Heneral Douglas MacArthur sa Maynila noong Disyembre 26, 1941 upang maiwasan ang pagkawasak nito?',
          options: const [
            QuestionOption(label: 'A', text: 'Idineklarang "Open City"'),
            QuestionOption(label: 'B', text: 'Sinunog ang buong lungsod'),
            QuestionOption(label: 'C', text: 'Ginawang kublihan ng militar'),
            QuestionOption(label: 'D', text: 'Ipinasara ang mga daungan'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang "Open City" ay nangangahulugang walang militar sa lungsod upang hindi ito bombahin.',
        ),
      ],
      3: [
        Question(
          id: 'ww2_3_1',
          era: 'ww2',
          gradeLevel: 'grade6',
          level: 3,
          questionText: 'Ano ang tawag sa malupit na pagpapadlakad sa libu-libong sundalong Pilipino at Amerikano mula Bataan hanggang Tarlac?',
          options: const [
            QuestionOption(label: 'A', text: 'Bataan Death March'),
            QuestionOption(label: 'B', text: 'Long March'),
            QuestionOption(label: 'C', text: 'Trail of Tears'),
            QuestionOption(label: 'D', text: 'Capas March'),
          ],
          correctAnswer: 'A',
          explanation: 'Pinaglakad ng mga Hapones ang mga sumukong sundalo nang may higit 100 kilometro nang walang pagkain at tubig.',
        ),
      ],
      4: [
        Question(
          id: 'ww2_4_1',
          era: 'ww2',
          gradeLevel: 'grade6',
          level: 4,
          questionText: 'Ano ang pangunahing samahan ng mga gerilyang magsasaka sa Gitnang Luzon na lumaban sa mga Hapon?',
          options: const [
            QuestionOption(label: 'A', text: 'Hukbalahap'),
            QuestionOption(label: 'B', text: 'Katipunan'),
            QuestionOption(label: 'C', text: 'USAFFE'),
            QuestionOption(label: 'D', text: 'MAKAPILI'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang Hukbo ng Bayan Laban sa Hapon (Hukbalahap) ay pinamunuan ni Luis Taruc.',
        ),
      ],
      5: [
        Question(
          id: 'ww2_5_1',
          era: 'ww2',
          gradeLevel: 'grade6',
          level: 5,
          questionText: 'Ano ang tawag sa perang papel na ipinalabas ng pamahalaang Hapon na itinuring na walang halaga ng mga Pilipino?',
          options: const [
            QuestionOption(label: 'A', text: 'Mickey Mouse Money'),
            QuestionOption(label: 'B', text: 'Yen'),
            QuestionOption(label: 'C', text: 'Peso Script'),
            QuestionOption(label: 'D', text: 'Dollar Script'),
          ],
          correctAnswer: 'A',
          explanation: 'Dahil sa matinding implasyon, ang perang Hapon ay tinawag na "Mickey Mouse Money".',
        ),
      ],
      6: [
        Question(
          id: 'ww2_6_1',
          era: 'ww2',
          gradeLevel: 'grade6',
          level: 6,
          questionText: 'Sino ang bayaning babae na nagtatag ng Girl Scouts of the Philippines at tumulong sa mga sundalo noong digmaan?',
          options: const [
            QuestionOption(label: 'A', text: 'Josefa Llanes Escoda'),
            QuestionOption(label: 'B', text: 'Tandang Sora'),
            QuestionOption(label: 'C', text: 'Gabriela Silang'),
            QuestionOption(label: 'D', text: 'Marina Dizon'),
          ],
          correctAnswer: 'A',
          explanation: 'Inialay ni Josefa Llanes Escoda ang kanyang buhay sa pagtulong sa mga bihag at gerilya.',
        ),
      ],
      7: [
        Question(
          id: 'ww2_7_1',
          era: 'ww2',
          gradeLevel: 'grade6',
          level: 7,
          questionText: 'Sino ang Pangulo ng Ikalawang Republika ng Pilipinas sa ilalim ng pamamahala ng mga Hapon (Puppet Republic)?',
          options: const [
            QuestionOption(label: 'A', text: 'Jose P. Laurel'),
            QuestionOption(label: 'B', text: 'Jorge Vargas'),
            QuestionOption(label: 'C', text: 'Benigno Aquino Sr.'),
            QuestionOption(label: 'D', text: 'Manuel Roxas'),
          ],
          correctAnswer: 'A',
          explanation: 'Si Jose P. Laurel ang nagmaniobra upang protektahan ang mga Pilipino sa kabila ng kontrol ng Hapon.',
        ),
      ],
      8: [
        Question(
          id: 'ww2_8_1',
          era: 'ww2',
          gradeLevel: 'grade6',
          level: 8,
          questionText: 'Anong tanyag na pangako ang itinupad ni Heneral Douglas MacArthur nang lumapag siya sa Leyte noong Oktubre 1944?',
          options: const [
            QuestionOption(label: 'A', text: '"I Shall Return"'),
            QuestionOption(label: 'B', text: '"I Have Fought"'),
            QuestionOption(label: 'C', text: '"Victory is Ours"'),
            QuestionOption(label: 'D', text: '"Freedom Today"'),
          ],
          correctAnswer: 'A',
          explanation: 'Tinupad ni MacArthur ang kanyang pangako nang magsimula ang pagpapalaya sa Leyte Gulf.',
        ),
      ],
      9: [
        Question(
          id: 'ww2_9_1',
          era: 'ww2',
          gradeLevel: 'grade6',
          level: 9,
          questionText: 'Ano ang itinuturing na isa sa pinaka-mapanirang labanan sa lungsod sa buong Ikalawang Digmaang Pandaigdig?',
          options: const [
            QuestionOption(label: 'A', text: 'Labanan sa Maynila (Battle of Manila)'),
            QuestionOption(label: 'B', text: 'Labanan sa Bataan'),
            QuestionOption(label: 'C', text: 'Labanan sa Corregidor'),
            QuestionOption(label: 'D', text: 'Labanan sa Bessang Pass'),
          ],
          correctAnswer: 'A',
          explanation: 'Noong Pebrero 1945, halos ganap na nawasak ang Maynila at higit 100,000 mamamayan ang nasawi.',
        ),
      ],
      10: [
        Question(
          id: 'ww2_10_1',
          era: 'ww2',
          gradeLevel: 'grade6',
          level: 10,
          questionText: 'Anong taon opisyal na sumuko ang Hapon at nagwakas ang Ikalawang Digmaang Pandaigdig?',
          options: const [
            QuestionOption(label: 'A', text: '1945'),
            QuestionOption(label: 'B', text: '1942'),
            QuestionOption(label: 'C', text: '1946'),
            QuestionOption(label: 'D', text: '1950'),
          ],
          correctAnswer: 'A',
          explanation: 'Sumuko ang Hapon noong Setyembre 1945 pagkatapos ng pagbomba sa Hiroshima at Nagasaki.',
        ),
      ],
    },

    // ─── 5. MAKABAGONG PANAHON (MODERN ERA) - GRADE 6 MELC ───────────────────
    'modern': {
      1: [
        Question(
          id: 'mod_1_1',
          era: 'modern',
          gradeLevel: 'grade6',
          level: 1,
          questionText: 'Sino ang huling Pangulo ng Commonwealth at Unang Pangulo ng Ikatlong Republika ng Pilipinas noong 1946?',
          options: const [
            QuestionOption(label: 'A', text: 'Manuel Roxas'),
            QuestionOption(label: 'B', text: 'Elpidio Quirino'),
            QuestionOption(label: 'C', text: 'Ramon Magsaysay'),
            QuestionOption(label: 'D', text: 'Diosdado Macapagal'),
          ],
          correctAnswer: 'A',
          explanation: 'Si Manuel Roxas ang nanumpa bilang Pangulo nang ibigay ng Amerika ang opisyal na kalayaan noong Hulyo 4, 1946.',
        ),
      ],
      2: [
        Question(
          id: 'mod_2_1',
          era: 'modern',
          gradeLevel: 'grade6',
          level: 2,
          questionText: 'Sino ang Pangulo na kilala bilang "Kampeon ng Masa" dahil sa kanyang malapit na pakikitungo sa karaniwang mamamayan?',
          options: const [
            QuestionOption(label: 'A', text: 'Ramon Magsaysay'),
            QuestionOption(label: 'B', text: 'Carlos P. Garcia'),
            QuestionOption(label: 'C', text: 'Ferdinand Marcos'),
            QuestionOption(label: 'D', text: 'Diosdado Macapagal'),
          ],
          correctAnswer: 'A',
          explanation: 'Binuksan ni Magsaysay ang Malacañang sa publiko at itinaguyod ang kapakanan ng mga magsasaka.',
        ),
      ],
      3: [
        Question(
          id: 'mod_3_1',
          era: 'modern',
          gradeLevel: 'grade6',
          level: 3,
          questionText: 'Anong patakaran ang ipinatupad ni Pangulong Carlos P. Garcia upang bigyang-prayoridad ang mga negosyanteng Pilipino?',
          options: const [
            QuestionOption(label: 'A', text: 'Filipino First Policy'),
            QuestionOption(label: 'B', text: 'Austerity Program'),
            QuestionOption(label: 'C', text: 'Green Revolution'),
            QuestionOption(label: 'D', text: 'Land Reform'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang "Filipino First Policy" ay nagbigay ng utos na tangkilikin muna ang produktong Pilipino.',
        ),
      ],
      4: [
        Question(
          id: 'mod_4_1',
          era: 'modern',
          gradeLevel: 'grade6',
          level: 4,
          questionText: 'Kailan idineklara ni Pangulong Ferdinand Marcos ang Batas Militar (Martial Law) sa pamamagitan ng Proklamasyon 1081?',
          options: const [
            QuestionOption(label: 'A', text: 'Setyembre 21, 1972'),
            QuestionOption(label: 'B', text: 'Pebrero 25, 1986'),
            QuestionOption(label: 'C', text: 'Hunyo 12, 1975'),
            QuestionOption(label: 'D', text: 'Nobyembre 30, 1970'),
          ],
          correctAnswer: 'A',
          explanation: 'Inilagay ang buong bansa sa ilalim ng Batas Militar noong Setyembre 21, 1972.',
        ),
      ],
      5: [
        Question(
          id: 'mod_5_1',
          era: 'modern',
          gradeLevel: 'grade6',
          level: 5,
          questionText: 'Anong tanyag na mapayapang rebolusyon noong Pebrero 22–25, 1986 ang nagpabagsak sa diktadura at nagbalik ng demokrasya?',
          options: const [
            QuestionOption(label: 'A', text: 'EDSA People Power Revolution'),
            QuestionOption(label: 'B', text: 'Himagsikan sa Kawit'),
            QuestionOption(label: 'C', text: 'First Quarter Storm'),
            QuestionOption(label: 'D', text: 'Kapariz Movement'),
          ],
          correctAnswer: 'A',
          explanation: 'Milyun-milyong Pilipino ang nagtipon sa EDSA nang walang karahasan upang ipaglaban ang kalayaan.',
        ),
      ],
      6: [
        Question(
          id: 'mod_6_1',
          era: 'modern',
          gradeLevel: 'grade6',
          level: 6,
          questionText: 'Sino ang kauna-unahang babaeng Pangulo ng Pilipinas at kinilala bilang "Ina ng Demokrasya"?',
          options: const [
            QuestionOption(label: 'A', text: 'Corazon C. Aquino'),
            QuestionOption(label: 'B', text: 'Gloria Macapagal-Arroyo'),
            QuestionOption(label: 'C', text: 'Imelda Marcos'),
            QuestionOption(label: 'D', text: 'Eva Macapagal'),
          ],
          correctAnswer: 'A',
          explanation: 'Naluklok si Corazon Aquino bilang Pangulo pagkatapos ng tagumpay ng People Power Revolution.',
        ),
      ],
      7: [
        Question(
          id: 'mod_7_1',
          era: 'modern',
          gradeLevel: 'grade6',
          level: 7,
          questionText: 'Anong Saligang Batas ang binuo at pinagtibay noong 1987 na ginagamit ng ating bansa hanggang sa kasalukuyan?',
          options: const [
            QuestionOption(label: 'A', text: '1987 Constitution'),
            QuestionOption(label: 'B', text: '1973 Constitution'),
            QuestionOption(label: 'C', text: '1935 Constitution'),
            QuestionOption(label: 'D', text: 'Malolos Constitution'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang 1987 Constitution ay naglalaman ng probisyon para sa Bill of Rights at paglimita sa kapangyarihan ng Pangulo.',
        ),
      ],
      8: [
        Question(
          id: 'mod_8_1',
          era: 'modern',
          gradeLevel: 'grade6',
          level: 8,
          questionText: 'Ano ang sistema ng pamahalaan kung saan ang kapangyarihan ay nanggagaling sa mamamayan sa pamamagitan ng malayang pagboto?',
          options: const [
            QuestionOption(label: 'A', text: 'Demokrasya'),
            QuestionOption(label: 'B', text: 'Diktadura'),
            QuestionOption(label: 'C', text: 'Monarkiya'),
            QuestionOption(label: 'D', text: 'Oligarkiya'),
          ],
          correctAnswer: 'A',
          explanation: 'Sa demokrasya, ang mamamayan ang may karapatang pumili ng mga pinuno ng bansa.',
        ),
      ],
      9: [
        Question(
          id: 'mod_9_1',
          era: 'modern',
          gradeLevel: 'grade6',
          level: 9,
          questionText: 'Ano ang pambansang pambansang ibon ng Pilipinas na idineklara sa ilalim ng Batas Republika 8477?',
          options: const [
            QuestionOption(label: 'A', text: 'Agila ng Pilipinas (Philippine Eagle)'),
            QuestionOption(label: 'B', text: 'Maya'),
            QuestionOption(label: 'C', text: 'Kalaw'),
            QuestionOption(label: 'D', text: 'Taktak'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang Philippine Eagle ay simbolo ng lakas, kalayaan, at pambansang pagkakakilanlan.',
        ),
      ],
      10: [
        Question(
          id: 'mod_10_1',
          era: 'modern',
          gradeLevel: 'grade6',
          level: 10,
          questionText: 'Ano ang pinakamahalagang tungkulin ng bawat batang Pilipino para sa hinaharap ng ating bansa?',
          options: const [
            QuestionOption(label: 'A', text: 'Mag-aral nang mabuti at igalang ang batas'),
            QuestionOption(label: 'B', text: 'Magtrabaho agad sa ibang bansa'),
            QuestionOption(label: 'C', text: 'Umiwas sa pakikilahok sa lipunan'),
            QuestionOption(label: 'D', text: 'Gumamit lamang ng gadyet'),
          ],
          correctAnswer: 'A',
          explanation: 'Ang edukasyon at pagiging responsableng mamamayan ang susi sa kaunlaran ng Pilipinas.',
        ),
      ],
    },
  };

  /// Retrieves local MELC-aligned questions for a given Era and Level.
  static List<Question> getQuestions(String era, int level) {
    final eraMap = _bank[era];
    if (eraMap == null) return _fallbackQuestions(era, level);

    final questions = eraMap[level];
    if (questions == null || questions.isEmpty) {
      return _fallbackQuestions(era, level);
    }

    if (questions.length < 10) {
      final padded = List<Question>.from(questions);
      final startIndex = padded.length;
      final grade = questions.isNotEmpty ? questions.first.gradeLevel : 'grade5';
      
      padded.addAll(List.generate(10 - startIndex, (i) {
        final qNum = startIndex + i + 1;
        return Question(
          id: '${era}_${level}_$qNum',
          era: era,
          level: level,
          gradeLevel: grade,
          questionText: 'Dagdag na tanong $qNum para sa $era antas $level. (Kailangang palitan ng totoong tanong)',
          options: const [
            QuestionOption(label: 'A', text: 'Tamang Sagot'),
            QuestionOption(label: 'B', text: 'Maling Sagot 1'),
            QuestionOption(label: 'C', text: 'Maling Sagot 2'),
            QuestionOption(label: 'D', text: 'Maling Sagot 3'),
          ],
          correctAnswer: 'A',
          explanation: 'Paliwanag ng placeholder.',
        );
      }));
      return padded;
    }

    return questions;
  }

  static List<Question> _fallbackQuestions(String era, int level) {
    return List.generate(
      10,
      (i) => Question(
        id: '${era}_${level}_$i',
        era: era,
        level: level,
        questionText: 'Tanong ${i + 1}: Sino ang pambansang bayani ng Pilipinas?',
        options: const [
          QuestionOption(label: 'A', text: 'Dr. Jose Rizal'),
          QuestionOption(label: 'B', text: 'Andres Bonifacio'),
          QuestionOption(label: 'C', text: 'Apolinario Mabini'),
          QuestionOption(label: 'D', text: 'Emilio Aguinaldo'),
        ],
        correctAnswer: 'A',
        explanation: 'Si Dr. Jose Rizal ang ating Pambansang Bayani.',
      ),
    );
  }
}