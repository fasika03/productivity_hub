import 'storage.dart';

/// Tracks how long the app is used in total per day, and how long each
/// screen/tool is active, so the Screen Time view can show a breakdown.
/// Data is stored per calendar day (YYYY-MM-DD) as:
///   { "total": <seconds>, "screens": { "Tasks": <seconds>, ... } }
class ScreenTimeTracker {
  static final ScreenTimeTracker _instance = ScreenTimeTracker._internal();
  factory ScreenTimeTracker() => _instance;
  ScreenTimeTracker._internal();

  static const String _storageKey = 'screen-time';

  Map<String, dynamic> _data = {};
  bool _loaded = false;

  String? _activeScreen;
  DateTime? _activeSince;

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _data = await Storage.loadMap(_storageKey);
    _loaded = true;
  }

  Map<String, dynamic> _entryFor(String key) {
    final existing = _data[key];
    if (existing is Map) {
      return {
        'total': (existing['total'] as num?)?.toInt() ?? 0,
        'screens': Map<String, dynamic>.from(existing['screens'] as Map? ?? {}),
      };
    }
    return {'total': 0, 'screens': <String, dynamic>{}};
  }

  /// Adds any accumulated time for the currently active screen to storage,
  /// without changing which screen is considered active.
  void _flush() {
    if (_activeScreen == null || _activeSince == null) return;
    final now = DateTime.now();
    final elapsed = now.difference(_activeSince!).inSeconds;
    _activeSince = now;
    if (elapsed <= 0) return;

    final key = _dateKey(now);
    final entry = _entryFor(key);
    entry['total'] = (entry['total'] as int) + elapsed;
    final screens = Map<String, dynamic>.from(entry['screens'] as Map);
    screens[_activeScreen!] = ((screens[_activeScreen!] as int?) ?? 0) + elapsed;
    entry['screens'] = screens;
    _data[key] = entry;
    Storage.save(_storageKey, _data);
  }

  /// Call when a screen/tab becomes the visible one (tab switch, or app
  /// resumed from background while that tab is showing).
  Future<void> enterScreen(String screenName) async {
    await _ensureLoaded();
    _flush();
    _activeScreen = screenName;
    _activeSince = DateTime.now();
  }

  /// Call when the app is backgrounded — stops the clock until it resumes.
  Future<void> pause() async {
    await _ensureLoaded();
    _flush();
    _activeScreen = null;
    _activeSince = null;
  }

  /// Today's totals, including any time accumulated in the current session.
  Future<Map<String, dynamic>> today() async {
    await _ensureLoaded();
    _flush();
    return _entryFor(_dateKey(DateTime.now()));
  }

  /// The last [n] days (oldest first), including today, as date-key/entry pairs.
  Future<List<MapEntry<String, Map<String, dynamic>>>> lastNDays(int n) async {
    await _ensureLoaded();
    _flush();
    final now = DateTime.now();
    final result = <MapEntry<String, Map<String, dynamic>>>[];
    for (int i = n - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = _dateKey(d);
      result.add(MapEntry(key, _entryFor(key)));
    }
    return result;
  }
}

String formatDuration(int totalSeconds) {
  if (totalSeconds < 60) return '<1m';
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}
