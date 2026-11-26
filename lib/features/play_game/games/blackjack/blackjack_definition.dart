import 'dart:math';
import '../../../../core/game/game_definition.dart';
import '../../../../core/game/game_model.dart';
import 'blackjack.dart';

class BlackjackDefinition extends GameDefinition {
  const BlackjackDefinition();
  @override GameType get type => GameType.blackjack;
  @override String get name => Blackjack.gameName;
  @override String get description => 'Hit or stand against the dealer';
  @override String get lobbyInfo => 'The dealer is automatic. You can play alone.';
  @override String get symbol => '♣';
  @override int get minPlayers => Blackjack.minPlayers;
  @override int get maxPlayers => Blackjack.maxPlayers;
  
  
  @override TableGame createGame(List<TablePlayer> players, Random random, {int initialHandSize = 5}) => Blackjack(players, random);
}
