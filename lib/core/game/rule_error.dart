class RuleError implements Exception {
  final String message;
  const RuleError(this.message);
  @override
  String toString() => message;
}

void require(bool condition, String message) {
  if (!condition) throw RuleError(message);
}
