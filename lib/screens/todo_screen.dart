import 'package:flutter/material.dart';
import '../theme.dart';
import '../storage.dart';
import '../notifications.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Map<String, dynamic>> _todos = [];
  final _controller = TextEditingController();
  String _priority = 'medium';
  String _filter = 'all';
  DateTime? _reminderAt;

  static const _priorities = ['low', 'medium', 'high'];
  static const _priorityColors = {
    'low': AppColors.sage,
    'medium': AppColors.gold,
    'high': AppColors.terracotta,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await Storage.loadList('todos');
    setState(() => _todos = data);
  }

  Future<void> _persist() async {
    await Storage.save('todos', _todos);
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderAt != null
          ? TimeOfDay.fromDateTime(_reminderAt!)
          : const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _reminderAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final id = generateId();
    final reminderAt = _reminderAt;
    setState(() {
      _todos.add({
        'id': id,
        'text': text,
        'done': false,
        'priority': _priority,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'reminderAt': reminderAt?.millisecondsSinceEpoch,
      });
      _controller.clear();
      _priority = 'medium';
      _reminderAt = null;
    });
    _persist();
    if (reminderAt != null) {
      NotificationService().scheduleAt(
        id: notificationIdFor(id),
        title: 'Task reminder',
        body: text,
        dateTime: reminderAt,
      );
    }
  }

  void _toggle(String id) {
    late bool nowDone;
    setState(() {
      final t = _todos.firstWhere((e) => e['id'] == id);
      t['done'] = !(t['done'] as bool);
      nowDone = t['done'] as bool;
    });
    _persist();
    if (nowDone) {
      NotificationService().cancel(notificationIdFor(id));
    }
  }

  void _delete(String id) {
    setState(() => _todos.removeWhere((e) => e['id'] == id));
    _persist();
    NotificationService().cancel(notificationIdFor(id));
  }

  String _formatReminder(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $hour12:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _todos.where((t) {
      if (_filter == 'active') return t['done'] == false;
      if (_filter == 'completed') return t['done'] == true;
      return true;
    }).toList()
      ..sort((a, b) {
        final doneCompare = (a['done'] as bool ? 1 : 0).compareTo(b['done'] as bool ? 1 : 0);
        if (doneCompare != 0) return doneCompare;
        return (a['createdAt'] as int).compareTo(b['createdAt'] as int);
      });

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Add a task…'),
            onSubmitted: (_) => _addTodo(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ..._priorities.map((p) {
                final active = _priority == p;
                final color = _priorityColors[p]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(p[0].toUpperCase() + p.substring(1)),
                    selected: active,
                    onSelected: (_) => setState(() => _priority = p),
                    selectedColor: color,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: color),
                  ),
                );
              }),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addTodo,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.inkDark,
                  foregroundColor: AppColors.textLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: _pickReminder,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _reminderAt != null ? AppColors.goldSoft.withOpacity(0.25) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _reminderAt != null ? AppColors.gold : AppColors.parchmentLine,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        size: 15,
                        color: _reminderAt != null ? AppColors.gold : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _reminderAt != null ? _formatReminder(_reminderAt!.millisecondsSinceEpoch) : 'Set reminder',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _reminderAt != null ? AppColors.textDark : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_reminderAt != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                  onPressed: () => setState(() => _reminderAt = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: ['all', 'active', 'completed'].map((f) {
              final active = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f[0].toUpperCase() + f.substring(1)),
                  selected: active,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: AppColors.sage,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: active ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: const BorderSide(color: AppColors.parchmentLine),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('✎', style: displayFont(size: 32, color: AppColors.gold)),
                        const SizedBox(height: 8),
                        const Text(
                          'Nothing here yet. Add your first task above.',
                          style: TextStyle(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final t = filtered[i];
                      final done = t['done'] as bool;
                      final priority = t['priority'] as String;
                      final reminderAt = t['reminderAt'] as int?;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.parchmentLine),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _toggle(t['id'] as String),
                              child: Container(
                                width: 22,
                                height: 22,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: done ? AppColors.sage : Colors.white,
                                  border: Border.all(color: AppColors.sage, width: 1.6),
                                ),
                                child: done
                                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['text'] as String,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      color: done ? AppColors.textMuted : AppColors.textDark,
                                      decoration: done ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        priority,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _priorityColors[priority],
                                        ),
                                      ),
                                      if (reminderAt != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.notifications_outlined, size: 12, color: AppColors.textMuted),
                                            const SizedBox(width: 3),
                                            Text(
                                              _formatReminder(reminderAt),
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                              onPressed: () => _delete(t['id'] as String),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
