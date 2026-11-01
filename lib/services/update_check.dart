import 'package:dio/dio.dart';
import '../core/app_info.dart';
import '../core/constants.dart';

/// What the download site says about the newest version. It is a small file
/// (`latest.json`) kept next to the public page:
///
/// ```json
/// {
///   "version": "1.3.3",
///   "required": false,
///   "notes": ["Saved na ang coins mo kahit magpalit ng phone"],
///   "reason": "Hindi na makaka-save ng coins at score ang old version",
///   "url": "https://chronoquest-five.vercel.app"
/// }
/// ```
///
/// `required` is for the rare time an old copy would break. `reason` is shown
/// only then. `url` is where the download button goes; the site itself if absent.
class LatestVersion {
  final String version;
  final bool required;
  final List<String> notes;
  final String? reason;
  final String url;

  const LatestVersion({
    required this.version,
    this.required = false,
    this.notes = const [],
    this.reason,
    this.url = UpdateConstants.siteUrl,
  });

  /// Null when the file is not what we expect (no readable version), so a broken
  /// file shows nothing instead of a broken card.
  static LatestVersion? fromJson(Object? json) {
    if (json is! Map) return null;
    final version = json['version'];
    if (version is! String || parseVersion(version) == null) return null;
    final notes = json['notes'];
    final reason = json['reason'];
    final url = json['url'];
    return LatestVersion(
      version: version.trim(),
      required: json['required'] == true,
      notes: [
        if (notes is List)
          for (final n in notes)
            if (n is String && n.trim().isNotEmpty) n.trim(),
      ].take(4).toList(),
      reason:
          reason is String && reason.trim().isNotEmpty ? reason.trim() : null,
      url: url is String && url.startsWith('https://')
          ? url
          : UpdateConstants.siteUrl,
    );
  }
}

/// The numbers of a version such as "1.3.3", or null if it has none. Anything
/// after the numbers ("1.3.3-test", "1.3.3 TEST") is ignored: a tester build is
/// the same version as the student build.
List<int>? parseVersion(String text) {
  final m = RegExp(r'^\s*(\d+)\.(\d+)\.(\d+)').firstMatch(text);
  if (m == null) return null;
  return [for (var i = 1; i <= 3; i++) int.parse(m.group(i)!)];
}

/// Negative if [a] is older than [b], 0 if the same, positive if newer. A version
/// that cannot be read counts as the same, so nobody is told to update by mistake.
int compareVersions(String a, String b) {
  final x = parseVersion(a);
  final y = parseVersion(b);
  if (x == null || y == null) return 0;
  for (var i = 0; i < 3; i++) {
    if (x[i] != y[i]) return x[i] - y[i];
  }
  return 0;
}

class UpdateCheck {
  /// The newest version when it is newer than [current], else null. Also null
  /// with no internet, a slow or broken site, or a file we cannot read: the game
  /// never waits on this and never shows an error for it.
  static Future<LatestVersion?> fetch(
      {Dio? dio, String current = appVersion, String? url}) async {
    try {
      // Its own client: the game's main one carries the login token and the API's
      // address, and this file is on a public site.
      final client = dio ??
          Dio(BaseOptions(
            connectTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 6),
          ));
      final response = await client.get<Object?>(
        url ?? UpdateConstants.latestUrl,
        options: Options(responseType: ResponseType.json),
      );
      final latest = LatestVersion.fromJson(response.data);
      if (latest == null || compareVersions(latest.version, current) <= 0) {
        return null;
      }
      return latest;
    } catch (_) {
      return null;
    }
  }
}
