/// A bank identifier is also a directory component on Windows and Android.
/// Keep existing non-UUID identifiers compatible, but reject path syntax.
bool isSafeBankId(String value) =>
    value.isNotEmpty &&
    value != '.' &&
    value != '..' &&
    !value.endsWith('.') &&
    !value.endsWith(' ') &&
    !RegExp(r'[\\/:*?"<>|\x00-\x1f]').hasMatch(value) &&
    !RegExp(
      r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)',
      caseSensitive: false,
    ).hasMatch(value);
