import 'dart:math';
import '../models/table_player.dart';
import '../models/game_view_state.dart';
import '../rule_error.dart';
import '../table_game.dart';
import 'standard_deck.dart';

abstract class StandardCardGame extends TableGame {
  final List<String> deck;
  final Map<String, List<String>> hands;
  StandardCardGame(List<TablePlayer> players, Random random)
    : deck = standardDeck(random), hands = {for (final p in players) p.id: <String>[]},
      super(players, random);
  List<String> handOf(String id) => hands[id]!;
  void draw(String id) {
    require(deck.isNotEmpty, 'The draw pile is empty');
    handOf(id).add(deck.removeLast());
  }
  void checkSelection(String id, List<String> cards) {
    require(cards.isNotEmpty, 'Select at least one card');
    require(cards.toSet().length == cards.length && cards.every(handOf(id).contains), 'You do not own those cards');
  }
  void removeCards(String id, List<String> cards) {
    for (final card in cards) { handOf(id).remove(card); }
  }
  List<PlayerView> cardPlayers({String? turn, Set<String> active = const {},
    Map<String, String> notes = const {}}) => [
    for (final p in players) PlayerView.fromPlayer(p, count: handOf(p.id).length,
      turn: turn == p.id || active.contains(p.id), note: notes[p.id] ?? ''),
  ];
}
