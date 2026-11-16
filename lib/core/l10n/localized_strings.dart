/// Base for every feature's string table.
abstract class LocalizedStrings {
  const LocalizedStrings(this.isNe);
  final bool isNe;

  String t(String en, String ne) => isNe ? ne : en;
}
