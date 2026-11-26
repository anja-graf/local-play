import '../rule_error.dart';

class TableAction {
  final String id;
  final List<String> cards;
  const TableAction(this.id, [this.cards = const []]);

  factory TableAction.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final cards = json['cards'] ?? const [];
    require(id is String && id.length <= 100, 'Invalid action');
    require(cards is List && cards.length <= 52 && cards.every((c) => c is String), 'Invalid cards');
    return TableAction(id as String, List<String>.from(cards as List));
  }
}

/// Describes an action the current player is allowed to attempt.
class ActionView {
  final String id;
  final String label;
  final bool selection;
  const ActionView(this.id, this.label, {this.selection = false});

  TableAction toAction([Iterable<String> selected = const []]) =>
      TableAction(id, selection ? List.unmodifiable(selected) : const []);

  Map<String, dynamic> toJson() => {
    'id': id, 'label': label, 'selection': selection,
  };
}

ActionView actionButton(String id, String label, {bool selection = false}) =>
    ActionView(id, label, selection: selection);
