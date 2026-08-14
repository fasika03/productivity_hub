import 'package:flutter/material.dart';
import '../theme.dart';
import '../storage.dart';

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

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _todos.add({
        'id': generateId(),
        'text': text,
        'done': false,
        'priority': _priority,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      _controller.clear();
      _priority = 'medium';
    });
    _persist();
  }

  void _toggle(String id) {
    setState(() {
      final t = _todos.firstWhere((e) => e['id'] == id);
      t['done'] = !(t['done'] as bool);
    });
    _persist();
  }

  void _delete(String id) {
    setState(() => _todos.removeWhere((e) => e['id'] == id));
    _persist();
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
                                  Text(
                                    priority,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _priorityColors[priority],
                                    ),
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
