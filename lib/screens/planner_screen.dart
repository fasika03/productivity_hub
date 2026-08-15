import 'package:flutter/material.dart';
import '../theme.dart';
import '../storage.dart';
import '../notifications.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  // DateTime.monday == 1 ... DateTime.sunday == 7, matching _days order.
  static const _weekdayNumbers = [1, 2, 3, 4, 5, 6, 7];

  List<Map<String, dynamic>> _sessions = [];
  final _subjectController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  String _day = 'Mon';
  TimeOfDay _time = const TimeOfDay(hour: 16, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await Storage.loadList('planner-sessions');
    setState(() => _sessions = data);
  }

  Future<void> _persist() async {
    await Storage.save('planner-sessions', _sessions);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  String _formatTime(TimeOfDay t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $ampm';
  }

  void _addSession() {
    final subject = _subjectController.text.trim();
    if (subject.isEmpty) return;
    final id = generateId();
    final weekday = _weekdayNumbers[_days.indexOf(_day)];
    setState(() {
      _sessions.add({
        'id': id,
        'subject': subject,
        'day': _day,
        'hour': _time.hour,
        'minute': _time.minute,
        'duration': int.tryParse(_durationController.text) ?? 30,
      });
      _subjectController.clear();
      _durationController.text = '45';
    });
    _persist();
    NotificationService().scheduleWeekly(
      id: notificationIdFor(id),
      title: 'Study session',
      body: '$subject — ${_formatTime(_time)}',
      weekday: weekday,
      hour: _time.hour,
      minute: _time.minute,
    );
  }

  void _removeSession(String id) {
    setState(() => _sessions.removeWhere((s) => s['id'] == id));
    _persist();
    NotificationService().cancel(notificationIdFor(id));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _subjectController,
            decoration:
                const InputDecoration(hintText: 'Subject (e.g. Biology)'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.parchmentLine),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(_formatTime(_time),
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textDark)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 84,
                child: TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Mins'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _days.map((d) {
                final active = _day == d;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(d),
                    selected: active,
                    onSelected: (_) => setState(() => _day = d),
                    selectedColor: AppColors.inkDark,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: active ? AppColors.textLight : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    side: const BorderSide(color: AppColors.parchmentLine),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.notifications_outlined,
                  size: 13, color: AppColors.textMuted),
              SizedBox(width: 5),
              Text(
                'A weekly reminder is scheduled automatically',
                style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addSession,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.inkDark,
                foregroundColor: AppColors.textLight,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _days.map((d) {
                final daySessions = _sessions
                    .where((s) => s['day'] == d)
                    .toList()
                  ..sort((a, b) {
                    final aMin = (a['hour'] as int) * 60 + (a['minute'] as int);
                    final bMin = (b['hour'] as int) * 60 + (b['minute'] as int);
                    return aMin.compareTo(bMin);
                  });
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.parchmentLine),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 6),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom:
                                  BorderSide(color: AppColors.parchmentLine)),
                        ),
                        child: Text(d, style: displayFont(size: 14)),
                      ),
                      if (daySessions.isEmpty)
                        const Text(
                          'No sessions',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic),
                        )
                      else
                        ...daySessions.map((s) {
                          final t = TimeOfDay(
                              hour: s['hour'] as int,
                              minute: s['minute'] as int);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 7),
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppColors.parchmentSoft,
                              borderRadius: BorderRadius.circular(3),
                              border: const Border(
                                  left: BorderSide(
                                      color: AppColors.sage, width: 3)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_formatTime(t)} · ${s['duration']}min',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        s['subject'] as String,
                                        style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _removeSession(s['id'] as String),
                                  child: const Icon(Icons.close,
                                      size: 16, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
