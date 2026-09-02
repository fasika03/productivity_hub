import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../storage.dart';
import '../notifications.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _Mode {
  final String key;
  final String label;
  final int mins;
  const _Mode(this.key, this.label, this.mins);
}

class _TimerScreenState extends State<TimerScreen> {
  static const _modes = [
    _Mode('focus', 'Focus 25', 25),
    _Mode('short', 'Short break 5', 5),
    _Mode('long', 'Long break 15', 15),
  ];

  String _mode = 'focus';
  int _totalSeconds = 25 * 60;
  int _remaining = 25 * 60;
  bool _running = false;
  int _completedToday = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await Storage.loadMap('timer-stats');
    final today = DateTime.now().toString().substring(0, 10);
    if (stats['date'] == today) {
      setState(() => _completedToday = (stats['completedToday'] as int?) ?? 0);
    }
  }

  Future<void> _saveStats() async {
    final today = DateTime.now().toString().substring(0, 10);
    await Storage.save('timer-stats', {'completedToday': _completedToday, 'date': today});
  }

  void _selectMode(_Mode m) {
    if (_running) return;
    setState(() {
      _mode = m.key;
      _totalSeconds = m.mins * 60;
      _remaining = m.mins * 60;
    });
  }

  void _toggleRunning() {
    if (_running) {
      _timer?.cancel();
      NotificationService().cancel(NotificationService.timerNotificationId);
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      NotificationService().scheduleAt(
        id: NotificationService.timerNotificationId,
        title: _mode == 'focus' ? 'Focus session complete' : 'Break\'s over',
        body: _mode == 'focus' ? 'Nice work — time for a break.' : 'Ready to focus again?',
        dateTime: DateTime.now().add(Duration(seconds: _remaining)),
        channelId: 'productivity_hub_timer',
        channelName: 'Pomodoro Timer',
      );
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remaining <= 1) {
            _remaining = 0;
            _running = false;
            timer.cancel();
            if (_mode == 'focus') {
              _completedToday++;
              _saveStats();
            }
          } else {
            _remaining--;
          }
        });
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    NotificationService().cancel(NotificationService.timerNotificationId);
    setState(() {
      _running = false;
      _remaining = _totalSeconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (_remaining % 60).toString().padLeft(2, '0');
    final progress = _totalSeconds == 0 ? 0.0 : 1 - (_remaining / _totalSeconds);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _modes.map((m) {
              final active = _mode == m.key;
              return ChoiceChip(
                label: Text(m.label.toUpperCase()),
                selected: active,
                onSelected: (_) => _selectMode(m),
                selectedColor: AppColors.inkDark,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: active ? AppColors.textLight : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
                side: const BorderSide(color: AppColors.parchmentLine),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: AppColors.parchmentLine,
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ),
                Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$mm:$ss',
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _mode == 'focus' ? 'FOCUS SESSION' : 'BREAK TIME',
                        style: const TextStyle(fontSize: 11.5, letterSpacing: 1.4, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _toggleRunning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.inkDark,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(_running ? 'Pause' : 'Start', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.parchmentLine),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              children: [
                const TextSpan(text: 'Focus sessions completed today: '),
                TextSpan(
                  text: '$_completedToday',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(8, (i) {
              final filledCount = _completedToday % 8 == 0 && _completedToday > 0 ? 8 : _completedToday % 8;
              final filled = i < filledCount;
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? AppColors.terracotta : AppColors.parchmentLine,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
