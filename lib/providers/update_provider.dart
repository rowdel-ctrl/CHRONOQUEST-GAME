import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../services/storage_service.dart';
import '../services/update_check.dart';

/// What the game knows about a newer version.
class UpdateState {
  /// The newest version, when it is newer than this phone's. Null when this phone
  /// is up to date, or when the check has not finished or could not be done.
  final LatestVersion? latest;

  /// The version the student tapped "Later" on.
  final String? dismissed;

  const UpdateState({this.latest, this.dismissed});

  bool get hasUpdate => latest != null;

  /// Whether the card is on screen: once for each version, unless the update is
  /// required, which keeps it up.
  bool get showCard {
    final l = latest;
    return l != null && (l.required || l.version != dismissed);
  }

  /// Whether the small "New update" chip stands in for the card: the student
  /// tapped "Later" and the version is still not installed.
  bool get showChip => hasUpdate && !showCard;
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  UpdateNotifier({
    Future<LatestVersion?> Function()? fetch,
    Future<void> Function(String url)? open,
    String? dismissed,
  })  : _fetch = fetch ?? UpdateCheck.fetch,
        _open = open ?? _openInBrowser,
        super(UpdateState(dismissed: dismissed));

  final Future<LatestVersion?> Function() _fetch;
  final Future<void> Function(String url) _open;
  bool _checking = false;
  bool _checked = false;

  static Future<void> _openInBrowser(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // No browser to open: nothing to do, the student can try again.
    }
  }

  /// Looks for a newer version, once each time the game is opened. [again] asks
  /// again even if it already did, for a phone that was offline the first time.
  Future<void> check({bool again = false}) async {
    if (_checking || (_checked && !again)) return;
    _checking = true;
    final latest = await _fetch();
    _checking = false;
    if (!mounted) return;
    _checked = true;
    // A failed or empty answer never takes away an update already found.
    if (latest != null) {
      state = UpdateState(latest: latest, dismissed: state.dismissed);
    }
  }

  /// "Later". Does nothing for a required update.
  void dismiss() {
    final l = state.latest;
    if (l == null || l.required) return;
    try {
      StorageService.setUpdateDismissed(l.version);
    } catch (_) {
      // Storage not opened (a test): the card is put away for this run anyway.
    }
    state = UpdateState(latest: l, dismissed: l.version);
  }

  /// "Download": opens the download page in the phone's browser.
  Future<void> openDownload() =>
      _open(state.latest?.url ?? UpdateConstants.siteUrl);
}

String? _savedDismissed() {
  try {
    return StorageService.getUpdateDismissed();
  } catch (_) {
    return null; // storage not opened (a test): nothing was dismissed
  }
}

final updateProvider = StateNotifierProvider<UpdateNotifier, UpdateState>(
  (ref) => UpdateNotifier(dismissed: _savedDismissed()),
);
