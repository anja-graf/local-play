import 'package:flutter/material.dart';
import '../../core/game/game_definition.dart';
import '../../core/game/game_model.dart';
import 'games/free_play/free_play_definition.dart';
import 'games/president/president_definition.dart';
import 'games/blackjack/blackjack_definition.dart';
import 'games/werewolf/werewolf_definition.dart';
import 'games/werewolf/werewolf_view.dart';
import 'widgets/default_game_view.dart';

typedef GameViewBuilder = Widget Function(
  GameViewState view,
  bool Function(TableAction) onAction,
);

class _GameRegistration {
  final GameDefinition definition;
  final GameViewBuilder builder;
  const _GameRegistration(this.definition, this.builder);
}

/// Registers game logic and its UI together, outside the core layer.
class GameRegistry {
  static final _entries = <_GameRegistration>[
    _GameRegistration(const FreePlayDefinition(), _defaultView),
    _GameRegistration(const PresidentDefinition(), _defaultView),
    _GameRegistration(const BlackjackDefinition(), _defaultView),
    _GameRegistration(const WerewolfDefinition(), _werewolfView),
  ];

  static List<GameDefinition> get games =>
      List.unmodifiable(_entries.map((entry) => entry.definition));

  static _GameRegistration _entryFor(GameType type) =>
      _entries.firstWhere((entry) => entry.definition.type == type);

  static GameDefinition forType(GameType type) => _entryFor(type).definition;

  static Widget buildView({
    required GameType type,
    required GameViewState view,
    required bool Function(TableAction) onAction,
  }) => _entryFor(type).builder(view, onAction);

  static Widget _defaultView(GameViewState view, bool Function(TableAction) onAction) =>
      DefaultGameView(key: ValueKey(view.gameType), view: view, onAction: onAction);

  static Widget _werewolfView(GameViewState view, bool Function(TableAction) onAction) =>
      WerewolfView(view: view, onAction: onAction);
}
