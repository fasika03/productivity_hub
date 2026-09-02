import 'package:flutter/material.dart';
import '../theme.dart';
import '../screen_time.dart';

class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  Map<String, dynamic>? _todayEntry;
  List<MapEntry<String, Map<String, dynamic>>> _week = [];
  bool _loading = true;

  static const _toolOrder = ['Tasks', 'Planner', 'Timer', 'Notes', 'GPA', 'Quotes'];
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

  String _weekdayLabel(String dateKey) {
    final parts = dateKey.split('-').map(int.parse).toList();
    final date = DateTime(parts[0], parts[1], parts[2]);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    final totalToday = (_todayEntry?['total'] as int?) ?? 0;
    final screens = Map<String, dynamic>.from(_todayEntry?['screens'] as Map? ?? {});
    final maxWeek = _week.fold<int>(
      1,
      (max, e) => ((e.value['total'] as int?) ?? 0) > max ? (e.value['total'] as int) : max,
    );

    final breakdown = _toolOrder
        .map((name) => MapEntry(name, (screens[name] as int?) ?? 0))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.gold,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: AppColors.inkDark, borderRadius: BorderRadius.circular(6)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TODAY IN PRODUCTIVITY HUB',
                    style: TextStyle(fontSize: 10.5, letterSpacing: 1, color: Color(0x99F2ECDC))),
                const SizedBox(height: 6),
                Text(formatDuration(totalToday),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.goldSoft)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('By tool today', style: displayFont(size: 16)),
          const SizedBox(height: 12),
          if (breakdown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('No activity recorded yet today.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
                          child: Text(e.key, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        ),
                        Text(formatDuration(e.value), style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
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
                      style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
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
                        color: isToday ? AppColors.inkDark : AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Time is tracked locally on this device only — nothing is sent anywhere.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
