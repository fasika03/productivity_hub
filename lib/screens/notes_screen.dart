import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../storage.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await Storage.loadList('notes');
    setState(() => _notes = data);
  }

  Future<void> _persist() async {
    await Storage.save('notes', _notes);
  }

  Future<void> _openNote(Map<String, dynamic>? note) async {
    Map<String, dynamic> target;
    if (note == null) {
      target = {
        'id': generateId(),
        'title': 'Untitled note',
        'body': '',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      setState(() => _notes.add(target));
      await _persist();
    } else {
      target = note;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditor(
          note: target,
          onChanged: (title, body) {
            target['title'] = title;
            target['body'] = body;
            target['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
            _persist();
          },
          onDelete: () {
            setState(() => _notes.removeWhere((n) => n['id'] == target['id']));
            _persist();
          },
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [..._notes]
      ..sort((a, b) => (b['updatedAt'] as int).compareTo(a['updatedAt'] as int));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openNote(null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.inkDark,
                foregroundColor: AppColors.textLight,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: sorted.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('☙', style: displayFont(size: 32, color: AppColors.gold)),
                        const SizedBox(height: 8),
                        const Text(
                          'No notes yet. Tap "New note" to begin.',
                          style: TextStyle(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final n = sorted[i];
                      return InkWell(
                        onTap: () => _openNote(n),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.parchmentLine),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (n['title'] as String).isEmpty ? 'Untitled' : n['title'] as String,
                                style: displayFont(size: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                (n['body'] as String).isEmpty ? 'No content' : n['body'] as String,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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

class NoteEditor extends StatefulWidget {
  final Map<String, dynamic> note;
  final void Function(String title, String body) onChanged;
  final VoidCallback onDelete;

  const NoteEditor({super.key, required this.note, required this.onChanged, required this.onDelete});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note['title'] as String);
    _bodyController = TextEditingController(text: widget.note['body'] as String);
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.onChanged(_titleController.text, _bodyController.text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.terracotta),
            onPressed: () {
              widget.onDelete();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              onChanged: (_) => _scheduleSave(),
              style: displayFont(size: 20),
              decoration: const InputDecoration(
                hintText: 'Note title',
                filled: false,
                border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.parchmentLine)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.parchmentLine)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: TextField(
                controller: _bodyController,
                onChanged: (_) => _scheduleSave(),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textDark),
                decoration: const InputDecoration(
                  hintText: 'Start writing…',
                  filled: false,
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
