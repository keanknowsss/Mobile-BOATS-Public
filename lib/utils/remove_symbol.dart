String removeSymbolsFromString(String input) {
  // Define a regular expression pattern to match the symbols
  final RegExp pattern = RegExp(r'[.#$\[\]]');

  // Use the replaceAll method to remove the symbols from the string
  String result = input.replaceAll(pattern, '');

  return result;
}
