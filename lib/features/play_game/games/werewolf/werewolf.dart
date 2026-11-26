import 'dart:math';
import '../../../../core/game/game_model.dart';

enum _Role {
  wolf('Werewolf', 'werewolf',
      'You are on the werewolf team. Each night, choose a victim. During the day, hide your identity and vote with the village. Your team wins when the living werewolves equal or outnumber the other living players.'),
  seer('Seer', 'seer',
      'You are on the village team. Each night, inspect one other living player to learn whether they are a werewolf. During the day, discuss and vote. The village wins when all werewolves are eliminated.'),
  villager('Villager', 'villager',
      'You are on the village team. You have no special night ability. During the day, discuss and vote to eliminate a suspected werewolf. The village wins when all werewolves are eliminated.');

  const _Role(this.label, this.assetId, this.description);
  final String label;
  final String assetId;
  final String description;

  String get assetPath => 'assets/cards/werewolf/$assetId.svg';
}

enum _Phase { night, day, ended }

class Werewolf extends TableGame {
  static const gameName = 'Werewolf';
  static const minPlayers = 5;
  static const maxPlayers = 6;
  @override GameType get type => GameType.werewolf;
  @override bool get allowsConcurrentActions => true;
  int _actionEpoch = 0;
  @override int get actionEpoch => _actionEpoch;
  final Map<String, _Role> _roles = {};
  final Set<String> _alive = {};
  final Map<String, String> _votes = {};
  final Map<String, String> _visions = {};
  _Phase _phase = _Phase.night;
  int _round = 1;
  String _announcement = 'The village falls asleep.';
  String _winner = '';

  Werewolf(List<TablePlayer> players, Random random) : super(players, random) {
    require(players.length >= minPlayers &&
      players.length <= maxPlayers,
      'Invalid number of Werewolf players');
    final shuffled = players.map((p) => p.id).toList()..shuffle(random);
    final wolves = players.length >= 7 ? 2 : 1;
    for (var i = 0; i < shuffled.length; i++) {
      _roles[shuffled[i]] = i < wolves ? _Role.wolf : i == wolves ? _Role.seer : _Role.villager;
    }
    _alive.addAll(shuffled); _progress();
  }
  @override String get title => gameName;
  @override bool get finished => _phase == _Phase.ended;
  List<String> get _voters => _alive.where((id) => _phase == _Phase.day || _roles[id] != _Role.villager).toList();
  bool _isSeerAtNight(String id) => _phase == _Phase.night && _roles[id] == _Role.seer;
  List<String> _targets(String id) => players.map((p) => p.id).where((p) => _alive.contains(p) && p != id &&
    (_phase != _Phase.night || _roles[id] != _Role.wolf || _roles[p] != _Role.wolf)).toList();
  void _record(String id, String target) {
    require(_targets(id).contains(target), 'Invalid target');
    _votes[id] = target;
    if (_isSeerAtNight(id)) {
      final role = _roles[target] == _Role.wolf ? 'werewolf' : 'not a werewolf';
      _visions[id] = 'Night $_round: ${nameOf(target)} is $role.';
    }
  }
  @override void apply(String playerId, TableAction action) {
    require(!finished && _voters.contains(playerId) && !_votes.containsKey(playerId), 'You cannot vote now');
    final prefix = _isSeerAtNight(playerId) ? 'inspect:' : 'vote:';
    require(action.id.startsWith(prefix), 'Invalid action');
    _record(playerId, action.id.substring(prefix.length)); _progress();
  }
  void _progress() {
    // Humans choose once per phase. Bots act automatically, with simple random choices.
    for (var guard = 0; !finished && guard < 100; guard++) {
      for (final id in _voters) {
        if (isBot(id) && !_votes.containsKey(id)) {
          final options = _targets(id);
          if (options.isNotEmpty) _record(id, options[random.nextInt(options.length)]);
        }
      }
      if (!_voters.every(_votes.containsKey)) return;
      final counts = <String, int>{};
      for (final entry in _votes.entries) {
        if (_phase == _Phase.day || _roles[entry.key] == _Role.wolf) {
          counts.update(entry.value, (v) => v + 1, ifAbsent: () => 1);
        }
      }
      String? victim;
      if (counts.isNotEmpty) {
        final highest = counts.values.reduce(max);
        final leaders = counts.keys.where((id) => counts[id] == highest).toList();
        if (leaders.length == 1) victim = leaders.single;
      }
      final wasNight = _phase == _Phase.night;
      if (victim != null) {
        _alive.remove(victim);
        _announcement = '${wasNight ? 'At dawn' : 'The village voted'}: ${nameOf(victim)} was eliminated (${_roles[victim]!.label}).';
      } else { _announcement = '${wasNight ? 'At dawn' : 'Day vote'}: tie — nobody was eliminated.'; }
      _votes.clear();
      _actionEpoch++;
      final wolves = _alive.where((id) => _roles[id] == _Role.wolf).length;
      if (wolves == 0 || wolves >= _alive.length - wolves) {
        _winner = wolves == 0 ? 'Village wins!' : 'Werewolves win!'; _phase = _Phase.ended; return;
      }
      if (wasNight) { _phase = _Phase.day; }
      else { _phase = _Phase.night; _round++; }
      // Avoid an unbounded synchronous loop if only bots remain and repeatedly tie.
      if (guard == 99) { _winner = 'Draw — phase limit reached.'; _phase = _Phase.ended; }
    }
  }
  @override GameViewState view(String playerId) {
    final role = _roles[playerId]!;
    final alive = _alive.contains(playerId);
    final private = StringBuffer('Your role: ${role.label.toUpperCase()}${alive ? '' : ' · eliminated'}\n\n${role.description}');
    if (role == _Role.wolf) {
      final team = players.where((p) => p.id != playerId && _roles[p.id] == _Role.wolf).map((p) => p.name).join(', ');
      if (team.isNotEmpty) private.write('\nOther werewolves: $team');
    }
    if (_visions.containsKey(playerId)) private.write('\n${_visions[playerId]}');
    // Do not expose night voters, votes, or living roles to other clients.
    final canVote = !finished && _voters.contains(playerId) && !_votes.containsKey(playerId);
    return projection(playerId: playerId, privateCard: role.assetPath, status: finished ? '$_announcement\n$_winner' : '$_announcement\n${_phase.name.toUpperCase()} $_round',
        privateText: private.toString(), tableLabel: 'Village',
        info: finished ? 'Roles revealed.' : _phase == _Phase.day ? 'Discuss together, then secretly vote for a player. A tie eliminates nobody.' : 'Werewolves choose a victim. The seer can inspect a player. Everyone else waits.',
        publicPlayers: [for (final p in players) PlayerView.fromPlayer(p,
          note: '${_alive.contains(p.id) ? 'Alive' : 'Eliminated'}${finished || !_alive.contains(p.id) ? ' · ${_roles[p.id]!.label}' : ''}')],
        actions: [if (canVote) for (final id in _targets(playerId))
          actionButton('${_isSeerAtNight(playerId) ? 'inspect' : 'vote'}:$id', '${_isSeerAtNight(playerId) ? 'Inspect' : 'Vote for'} ${nameOf(id)}')],
    );
  }
}
