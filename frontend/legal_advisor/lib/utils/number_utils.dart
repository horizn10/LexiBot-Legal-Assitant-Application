String convertToLocalizedNumbers(String text, String language) {
  if (language == 'hi' || language == 'ne') {
    return text.replaceAllMapped(RegExp(r'\d'), (match) {
      int digit = int.parse(match.group(0)!);
      const devanagariDigits = [
        '०',
        '१',
        '२',
        '३',
        '४',
        '५',
        '६',
        '७',
        '८',
        '९'
      ];
      return devanagariDigits[digit];
    });
  }
  return text;
}
