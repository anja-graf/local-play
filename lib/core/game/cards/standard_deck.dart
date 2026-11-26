import 'dart:math';

// IDs match assets/cards/standard/ SVG filenames.
const suits = ['heart', 'diamond', 'club', 'spade'];
const ranks = ['ace', 'two', 'three', 'four', 'five', 'six', 'seven',
  'eight', 'nine', 'ten', 'jack', 'queen', 'king'];
String rankOf(String card) => card.split('_').last;
List<String> standardDeck(Random random) => [
  for (final suit in suits) for (final rank in ranks) '${suit}_$rank',
]..shuffle(random);
