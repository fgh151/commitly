/// Utility for generating sequential task numbers.
class TaskNumberGenerator {
  TaskNumberGenerator._();

  /// Generate the next sequential task number string, zero-padded.
  ///
  /// Example: if [currentMax] is 5, returns "006".
  static String generate(int currentMax) {
    return (currentMax + 1).toString().padLeft(3, '0');
  }

  /// Parse a task number from a zero-padded string.
  ///
  /// Example: "001" -> 1.
  static int parse(String padded) {
    return int.parse(padded);
  }
}
