import 'dart:math';
import '../../../../core/game/game_definition.dart';
import '../../../../core/game/game_model.dart';
import 'president.dart';

class PresidentDefinition extends GameDefinition {
  const PresidentDefinition();
  @override GameType get type => GameType.president;
  @override String get name => President.gameName;
  @override String get description => 'Classic cards · get rid of your cards';
  @override String get lobbyInfo => 'Bots fill the table up to $minPlayers players.';
  @override String get symbol => '👑';
  @override int get minPlayers => President.minPlayers;
  @override int get maxPlayers => President.maxPlayers;
  @override bool get supportsBots => true;
  
  @override TableGame createGame(List<TablePlayer> players, Random random, {int initialHandSize = 5}) => President(players, random);
}
