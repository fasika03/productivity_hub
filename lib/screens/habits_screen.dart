import 'package:flutter/material.dart';
import '../theme.dart';
import '../storage.dart';
import '../habits.dart';
import '../notifications.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Map<String, dynamic>> _habits = [];
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await Storage.loadList('habits');
    setState(() => _habits = data);
  }

  Future<void> _persist() async {
    await Storage.save('habits', _habits);
  }

  void _addHabit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _habits.add({
        'id': generateId(),
        'name': name,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'completedDates': <String>[],
        'reminderEnabled': false,
        'reminderHour': 19,
        'reminderMinute': 0,
      });
      _controller.clear();
    });
    _persist();
  }

  void _deleteHabit(String id) {
    setState(() => _habits.removeWhere((h) => h['id'] == id));
    _persist();
    NotificationService().cancel(notificationIdFor(id));
  }

  void _toggleDate(String id, DateTime day) {
    final habit = _habits.firstWhere((h) => h['id'] == id);
    final dates = List<String>.from(habit['completedDates'] as List);
    final key = habitDateKey(day);
    setState(() {
      if (dates.contains(key)) {
        dates.remove(key);
      } else {
        dates.add(key);
      }
      habit['completedDates'] = dates;
    });
    _persist();
  }

  Future<void> _toggleReminder(Map<String, dynamic> habit, bool value) async {
    setState(() => habit['reminderEnabled'] = value);
    _persist();
    final id = habit['id'] as String;
    if (value) {
      await NotificationService().scheduleDaily(
        id: notificationIdFor(id),
        title: 'Habit reminder',
        body: '${habit['name']} — keep the streak going!',
        hour: habit['reminderHour'] as int,
        minute: habit['reminderMinute'] as int,
      );
    } else {
      await NotificationService().cancel(notificationIdFor(id));
    }
  }

  Future<void> _pickReminderTime(Map<String, dynamic> habit) async {
    final current = TimeOfDay(hour: habit['reminderHour'] as int, minute: habit['reminderMinute'] as int);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null) return;
    setState(() {
      habit['reminderHour'] = picked.hour;
      habit['reminderMinute'] = picked.minute;
    });
    _persist();
    if (habit['reminderEnabled'] == true) {
      await NotificationService().scheduleDaily(
        id: notificationIdFor(habit['id'] as String),
        title: 'Habit reminder',
        body: '${habit['name']} — keep the streak going!',
        hour: picked.hour,
        minute: picked.minute,
      );
    }
  }

  String _formatTime(int hour, int minute) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final min = minute.toString().padLeft(2, '0');
    return '$hour12:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = lastNDays(7, now);
    const weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Add a habit (e.g. Read for 20 min)'),
                  onSubmitted: (_) => _addHabit(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.inkDark,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Icon(Icons.add, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _habits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔥', style: displayFont(size: 32, color: AppColors.gold)),
                        const SizedBox(height: 8),
                        const Text(
                          'No habits yet. Add one above to start a streak.',
                          style: TextStyle(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _habits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final habit = _habits[i];
                      final doneDates = Set<String>.from(habit['completedDates'] as List);
                      final streak = currentStreak(doneDates, now);
                      final best = bestStreak(doneDates);
                      final reminderOn = habit['reminderEnabled'] as bool? ?? false;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.parchmentLine),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        habit['name'] as String,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Text('🔥', style: TextStyle(fontSize: 12)),
                                          const SizedBox(width: 4),
                                          Text(
                                            streak == 0 ? 'No streak yet' : '$streak day${streak == 1 ? '' : 's'}',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: streak > 0 ? AppColors.terracotta : AppColors.textMuted,
                                            ),
                                          ),
                                          if (best > streak) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              'best $best',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                                  onPressed: () => _deleteHabit(habit['id'] as String),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(7, (di) {
                                final day = days[di];
                                final key = habitDateKey(day);
                                final done = doneDates.contains(key);
                                final isToday = habitDateKey(now) == key;
                                return GestureDetector(
                                  onTap: () => _toggleDate(habit['id'] as String, day),
                                  child: Column(
                                    children: [
                                      Text(
                                        weekdayLetters[di],
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isToday ? AppColors.gold : AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: done ? AppColors.sage : Colors.white,
                                          border: Border.all(
                                            color: isToday ? AppColors.gold : AppColors.parchmentLine,
                                            width: isToday ? 1.6 : 1,
                                          ),
                                        ),
                                        child: done
                                            ? const Icon(Icons.check, size: 15, color: Colors.white)
                                            : null,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () => _pickReminderTime(habit),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.notifications_outlined,
                                    size: 14,
                                    color: reminderOn ? AppColors.gold : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      reminderOn
                                          ? 'Daily reminder at ${_formatTime(habit['reminderHour'] as int, habit['reminderMinute'] as int)}'
                                          : 'No daily reminder',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                    ),
                                  ),
                                  Switch(
                                    value: reminderOn,
                                    onChanged: (v) => _toggleReminder(habit, v),
                                    activeColor: AppColors.gold,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
