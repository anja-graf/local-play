import 'dart:math';
import '../../../../core/game/game_definition.dart';
import '../../../../core/game/game_model.dart';
import 'free_play.dart';

class FreePlayDefinition extends GameDefinition {
  const FreePlayDefinition();
  @override GameType get type => GameType.freePlay;
  @override String get name => FreePlay.gameName;
  @override String get description => 'No enforced game rules';
  @override String get lobbyInfo => 'Free play has no automatic opponent. You can experiment alone.';
  @override String get symbol => '♠';
  @override int get minPlayers => FreePlay.minPlayers;
  @override int get maxPlayers => FreePlay.maxPlayers;
  
  @override int get maxInitialHandSize => 8;
  @override TableGame createGame(List<TablePlayer> players, Random random, {int initialHandSize = 5}) => FreePlay(players, random, initialHandSize);
}
