class IdGenerator {
  IdGenerator._();

  static String create(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_$now';
  }
}
