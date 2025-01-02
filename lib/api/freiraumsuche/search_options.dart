enum Repetition {
  once("1"),
  weekly("2"),
  biWeekly("3");

  final String value;

  const Repetition(this.value);

  String serialize() {
    return value;
  }
}
