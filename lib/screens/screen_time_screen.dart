import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';
import '../theme.dart';
import '../screen_time.dart';

class _AppUsage {
  final String packageName;
  final String label;
  final int seconds;
  _AppUsage(
      {required this.packageName, required this.label, required this.seconds});
}

class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  Map<String, dynamic>? _todayEntry;
  List<MapEntry<String, Map<String, dynamic>>> _week = [];
  bool _loading = true;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool _checkedDevicePermission = false;
  bool _devicePermissionGranted = false;
  bool _loadingDeviceUsage = false;
  List<_AppUsage> _deviceApps = [];

  static const _toolOrder = [
    'Tasks',
    'Planner',
    'Timer',
    'Notes',
    'GPA',
    'Quotes'
  ];
  static const _toolColors = {
    'Tasks': AppColors.sage,
    'Planner': AppColors.gold,
    'Timer': AppColors.terracotta,
    'Notes': Color(0xFF7C93A8),
    'GPA': Color(0xFF9C7CA8),
    'Quotes': AppColors.goldSoft,
  };

  @override
  void initState() {
    super.initState();
    _load();
    if (_isAndroid) _checkDevicePermissionAndLoad();
  }

  Future<void> _load() async {
    final today = await ScreenTimeTracker().today();
    final week = await ScreenTimeTracker().lastNDays(7);
    if (!mounted) return;
    setState(() {
      _todayEntry = today;
      _week = week;
      _loading = false;
    });
  }

  Future<void> _refreshAll() async {
    await _load();
    if (_isAndroid && _devicePermissionGranted) await _loadDeviceUsage();
  }

  Future<void> _checkDevicePermissionAndLoad() async {
    bool granted = false;
    try {
      granted = await UsageStats.checkUsagePermission() ?? false;
    } catch (_) {
      granted = false;
    }
    if (!mounted) return;
    setState(() {
      _devicePermissionGranted = granted;
      _checkedDevicePermission = true;
    });
    if (granted) await _loadDeviceUsage();
  }

  Future<void> _requestDevicePermission() async {
    try {
      await UsageStats.grantUsagePermission();
    } catch (_) {
      // ignore — user may cancel out of Settings
    }
    // The user is taken to system Settings and returns manually; re-check
    // once they're back rather than assuming success immediately.
    if (mounted) await _checkDevicePermissionAndLoad();
  }

  Future<void> _loadDeviceUsage() async {
    setState(() => _loadingDeviceUsage = true);
    try {
      final end = DateTime.now();
      final start = DateTime(end.year, end.month, end.day);
      final stats = await UsageStats.queryUsageStats(start, end);

      final Map<String, int> totals = {};
      for (final info in stats) {
        final pkg = info.packageName;
        if (pkg == null || pkg.isEmpty) continue;
        final raw = double.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
        final secs = (raw / 1000).round();
        if (secs <= 0) continue;
        totals[pkg] = (totals[pkg] ?? 0) + secs;
      }

      final entries = totals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = entries.take(30);

      final List<_AppUsage> result = [];
      for (final e in top) {
        result.add(_AppUsage(
            packageName: e.key,
            label: _friendlyLabel(e.key),
            seconds: e.value));
      }

      if (mounted) setState(() => _deviceApps = result);
    } catch (_) {
      // leave the list as-is; the UI shows an empty state
    } finally {
      if (mounted) setState(() => _loadingDeviceUsage = false);
    }
  }

  /// Turns a package name like "com.whatsapp" or "com.google.android.gm"
  /// into a readable guess like "Whatsapp" or "Gm", since without a
  /// package-info lookup we only have the raw package name to go on.
  String _friendlyLabel(String packageName) {
    final parts = packageName.split('.');
    final last = parts.isNotEmpty ? parts.last : packageName;
    if (last.isEmpty) return packageName;
    return last[0].toUpperCase() + last.substring(1);
  }

  String _weekdayLabel(String dateKey) {
    final parts = dateKey.split('-').map(int.parse).toList();
    final date = DateTime(parts[0], parts[1], parts[2]);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
    }

    final totalToday = (_todayEntry?['total'] as int?) ?? 0;
    final screens =
        Map<String, dynamic>.from(_todayEntry?['screens'] as Map? ?? {});
    final maxWeek = _week.fold<int>(
      1,
      (max, e) => ((e.value['total'] as int?) ?? 0) > max
          ? (e.value['total'] as int)
          : max,
    );

    final breakdown = _toolOrder
        .map((name) => MapEntry(name, (screens[name] as int?) ?? 0))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final deviceTotal = _deviceApps.fold<int>(0, (sum, a) => sum + a.seconds);
    final deviceMax = _deviceApps.isEmpty ? 1 : _deviceApps.first.seconds;

    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: AppColors.gold,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                color: AppColors.inkDark,
                borderRadius: BorderRadius.circular(6)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TODAY IN PRODUCTIVITY HUB',
                    style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1,
                        color: Color(0x99F2ECDC))),
                const SizedBox(height: 6),
                Text(formatDuration(totalToday),
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldSoft)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('By tool today', style: displayFont(size: 16)),
          const SizedBox(height: 12),
          if (breakdown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('No activity recorded yet today.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            )
          else
            ...breakdown.map((e) {
              final frac = totalToday > 0 ? e.value / totalToday : 0.0;
              final color = _toolColors[e.key] ?? AppColors.sage;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(e.key,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark)),
                        ),
                        Text(formatDuration(e.value),
                            style: const TextStyle(
                                fontSize: 12.5, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: frac.clamp(0.02, 1.0),
                        minHeight: 8,
                        backgroundColor: AppColors.parchmentLine,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 26),
          Text('Past 7 days', style: displayFont(size: 16)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.parchmentLine),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _week.map((e) {
                final total = (e.value['total'] as int?) ?? 0;
                final heightFrac = maxWeek > 0 ? total / maxWeek : 0.0;
                final isToday = e.key == _week.last.key;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total > 0 ? formatDuration(total) : '',
                      style: const TextStyle(
                          fontSize: 9.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: 8 + heightFrac * 90,
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.gold : AppColors.sage,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _weekdayLabel(e.key),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isToday ? AppColors.inkDark : AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Time is tracked locally on this device only — nothing is sent anywhere.',
            style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Text('All apps on this device today', style: displayFont(size: 16)),
          const SizedBox(height: 12),
          if (!_isAndroid)
            _buildNotice(
              "iOS doesn't let regular apps read how long you've spent in "
              "other apps — that data is restricted to Apple's own Screen "
              "Time system. Everything above still tracks Productivity Hub "
              "itself accurately on any device.",
            )
          else if (!_checkedDevicePermission)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold)),
            )
          else if (!_devicePermissionGranted)
            _buildPermissionCard()
          else
            _buildDeviceAppsList(deviceTotal, deviceMax),
        ],
      ),
    );
  }

  Widget _buildNotice(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.parchmentLine),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textMuted, height: 1.5)),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.parchmentLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "To show today's usage across all your apps, Android needs "
            "one-time permission via Settings → Usage Access.",
            style: TextStyle(
                fontSize: 13, color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _requestDevicePermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.inkDark,
              foregroundColor: AppColors.textLight,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Grant access',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceAppsList(int totalSeconds, int maxSeconds) {
    if (_loadingDeviceUsage && _deviceApps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }
    if (_deviceApps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'No usage recorded yet today. Pull down to refresh.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total: ${formatDuration(totalSeconds)}',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark),
        ),
        const SizedBox(height: 10),
        ..._deviceApps.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.parchmentLine),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      color: AppColors.parchmentSoft,
                      child: const Icon(Icons.apps,
                          size: 18, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: maxSeconds == 0 ? 0 : a.seconds / maxSeconds,
                            minHeight: 5,
                            backgroundColor: AppColors.parchmentSoft,
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.gold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatDuration(a.seconds),
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
