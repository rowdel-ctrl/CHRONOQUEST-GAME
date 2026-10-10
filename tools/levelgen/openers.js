'use strict';
// The six era openers, authored by hand: for each of the ten sections, the set
// pieces in the order a student meets them. The generator only fills in sizes
// and enemy kinds from its seed; the shape of the level is written here, so each
// opener teaches its era's landscape and introduces every kind of obstacle once,
// gently, before the rest of the era leans on them.
//
// A piece is its name, with "+e" when it carries a walker on top (on a bridge, a
// guard on a platform) and "+h" a Heavy (only where the era has one; elsewhere it
// falls back to a walker):
//   gap  gapPlain  walker  heavy  hill  mesa  courtyard  pillars  bridge  tower  fight
// Every section holds an enemy, and a section is at most two pieces so they fit.
const OPENERS = {
  // Sinaunang Pilipinas: rolling hills and rivers, wide open country.
  'pre-colonial': [
    ['gap', 'walker'],
    ['hill+e', 'gap'],
    ['gap', 'hill+e'],
    ['mesa', 'walker'],
    ['hill', 'walker'],
    ['bridge+e'],
    ['mesa+e', 'gap'],
    ['pillars', 'walker'],
    ['hill+e', 'gap'],
    ['hill', 'walker'],
  ],
  // Pananakop ng Espanya: fortress walls, towers and courtyards.
  spanish: [
    ['gap', 'walker'],
    ['mesa+e', 'gap'],
    ['hill', 'walker'],
    ['courtyard'],
    ['gap', 'mesa+e'],
    ['bridge+e'],
    ['tower', 'walker'],
    ['courtyard', 'gap'],
    ['mesa+e', 'gap'],
    ['hill', 'walker'],
  ],
  // Pag-usbong ng Nasyonalismo: towns on the rise, paths over streams.
  nationalism: [
    ['gap', 'walker'],
    ['hill+e', 'gap'],
    ['bridge+e'],
    ['mesa', 'walker'],
    ['hill+e', 'gap'],
    ['courtyard'],
    ['gap', 'hill+e'],
    ['pillars', 'walker'],
    ['mesa+e', 'gap'],
    ['hill', 'walker'],
  ],
  // Himagsikan at Imperyalismong Amerikano: broken country, river crossings.
  american: [
    ['gap', 'walker'],
    ['pillars', 'walker'],
    ['mesa+e', 'gap'],
    ['hill', 'walker'],
    ['bridge+e'],
    ['courtyard'],
    ['hill+e', 'gap'],
    ['tower', 'walker'],
    ['pillars', 'walker'],
    ['mesa+e', 'gap'],
  ],
  // Batas Militar at Muling Pagbangon: trenches and ruined walls.
  ww2: [
    ['gap', 'walker'],
    ['courtyard'],
    ['mesa+e', 'gap'],
    ['hill', 'walker'],
    ['courtyard', 'gap'],
    ['bridge+e'],
    ['mesa+e', 'gap'],
    ['tower+e'],
    ['hill+e', 'gap'],
    ['hill', 'walker'],
  ],
  // Modernong Pilipinas: steel and glass, towers and long crossings.
  modern: [
    ['gap', 'walker'],
    ['mesa+e', 'gap'],
    ['bridge+e'],
    ['hill', 'walker'],
    ['pillars', 'walker'],
    ['tower+e', 'gap'],
    ['courtyard'],
    ['hill+e', 'gap'],
    ['mesa+e', 'gap'],
    ['hill', 'walker'],
  ],
};

// Low-priority extras: a bump or a block after the authored pieces, kept only if
// the section has room, so the ground between them is never just flat.
const EXTRAS = ['bump', 'block', 'bump', 'bump', 'block', 'bump', 'block', 'bump', 'bump', 'block'];
for (const sections of Object.values(OPENERS)) {
  sections.forEach((pieces, i) => { if (pieces.length < 3 && !pieces.includes('courtyard')) pieces.push(EXTRAS[i]); });
}

module.exports = { OPENERS };
