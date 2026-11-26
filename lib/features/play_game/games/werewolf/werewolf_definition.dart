import 'dart:math';
import '../../../../core/game/game_definition.dart';
import '../../../../core/game/game_model.dart';
import 'werewolf.dart';

class WerewolfDefinition extends GameDefinition {
  const WerewolfDefinition();
  @override GameType get type => GameType.werewolf;
  @override String get name => Werewolf.gameName;
  @override String get description => 'Secret roles and social deduction';
  @override String get lobbyInfo => 'Bots fill the village up to $minPlayers players.';
  @override String get symbol => '☾';
  @override int get minPlayers => Werewolf.minPlayers;
  @override int get maxPlayers => Werewolf.maxPlayers;
  @override bool get supportsBots => true;
  
  @override TableGame createGame(List<TablePlayer> players, Random random, {int initialHandSize = 5}) => Werewolf(players, random);
}
