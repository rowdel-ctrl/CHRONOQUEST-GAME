/// Reads a class code out of what a section QR code holds.
///
/// The dashboard prints `chronoquest://join?code=<classCode>` (see
/// CHRONO-DASHBOARD/CDASH/src/utils/joinLink.js). A bare code is accepted too, so
/// a poster made some other way still scans. Anything else, such as a web link or
/// another app's QR, gives null.
///
/// The code comes back trimmed and upper-cased, the way the Class Code field
/// treats what a student types.
String? parseJoinCode(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;

  final uri = Uri.tryParse(text);
  if (uri != null && uri.hasScheme) {
    if (uri.scheme.toLowerCase() != 'chronoquest') return null;
    if (uri.host.toLowerCase() != 'join') return null;
    return _clean(uri.queryParameters['code']);
  }
  return _clean(text);
}

final _codeShape = RegExp(r'^[A-Z0-9_-]{2,20}$');

String? _clean(String? value) {
  final code = value?.trim().toUpperCase();
  if (code == null || !_codeShape.hasMatch(code)) return null;
  return code;
}
