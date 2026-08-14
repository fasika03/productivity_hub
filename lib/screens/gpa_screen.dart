import 'package:flutter/material.dart';
import '../theme.dart';
import '../storage.dart';

class GpaScreen extends StatefulWidget {
  const GpaScreen({super.key});

  @override
  State<GpaScreen> createState() => _GpaScreenState();
}

class _GpaScreenState extends State<GpaScreen> {
  static const _grades = ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F'];
  static const _gradePoints = {
    'A': 4.0,
    'A-': 3.7,
    'B+': 3.3,
    'B': 3.0,
    'B-': 2.7,
    'C+': 2.3,
    'C': 2.0,
    'C-': 1.7,
    'D+': 1.3,
    'D': 1.0,
    'F': 0.0,
  };

  List<Map<String, dynamic>> _courses = [];
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _creditControllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  TextEditingController _nameCtrl(Map<String, dynamic> c) {
    final id = c['id'] as String;
    return _nameControllers.putIfAbsent(id, () => TextEditingController(text: c['name'] as String));
  }

  TextEditingController _creditCtrl(Map<String, dynamic> c) {
    final id = c['id'] as String;
    return _creditControllers.putIfAbsent(id, () => TextEditingController(text: '${c['credits']}'));
  }

  @override
  void dispose() {
    for (final ctrl in _nameControllers.values) {
      ctrl.dispose();
    }
    for (final ctrl in _creditControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final data = await Storage.loadList('gpa-courses');
    setState(() {
      _courses = data.isEmpty
          ? [
              {'id': generateId(), 'name': '', 'credits': 3, 'grade': 'A'}
            ]
          : data;
    });
  }

  Future<void> _persist() async {
    await Storage.save('gpa-courses', _courses);
  }

  void _updateCourse(String id, String field, dynamic value) {
    setState(() {
      final c = _courses.firstWhere((e) => e['id'] == id);
      c[field] = value;
    });
    _persist();
  }

  void _cycleGrade(String id) {
    final c = _courses.firstWhere((e) => e['id'] == id);
    final idx = _grades.indexOf(c['grade'] as String);
    _updateCourse(id, 'grade', _grades[(idx + 1) % _grades.length]);
  }

  void _removeCourse(String id) {
    setState(() => _courses.removeWhere((c) => c['id'] == id));
    _nameControllers.remove(id)?.dispose();
    _creditControllers.remove(id)?.dispose();
    _persist();
  }

  void _addCourse() {
    setState(() => _courses.add({'id': generateId(), 'name': '', 'credits': 3, 'grade': 'A'}));
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    double points = 0;
    double credits = 0;
    for (final c in _courses) {
      final cr = (c['credits'] as num?)?.toDouble() ?? 0;
      final grade = c['grade'] as String?;
      if (cr > 0 && grade != null && _gradePoints.containsKey(grade)) {
        points += _gradePoints[grade]! * cr;
        credits += cr;
      }
    }
    final gpa = credits > 0 ? (points / credits).toStringAsFixed(2) : '0.00';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(flex: 3, child: Text('COURSE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
              SizedBox(width: 56, child: Text('CR', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
              SizedBox(width: 52, child: Text('GRADE', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
              SizedBox(width: 26),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _courses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = _courses[i];
                final id = c['id'] as String;
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _nameCtrl(c),
                        onChanged: (v) => _updateCourse(id, 'name', v),
                        style: const TextStyle(fontSize: 13.5),
                        decoration: const InputDecoration(hintText: 'Course name', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 56,
                      child: TextField(
                        controller: _creditCtrl(c),
                        onChanged: (v) => _updateCourse(id, 'credits', int.tryParse(v) ?? 0),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: const InputDecoration(isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _cycleGrade(id),
                      child: Container(
                        width: 52,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.inkDark,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c['grade'] as String,
                          style: const TextStyle(color: AppColors.goldSoft, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                      onPressed: () => _removeCourse(id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addCourse,
              icon: const Icon(Icons.add, size: 16, color: AppColors.textMuted),
              label: const Text('Add course', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.parchmentLine),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.inkDark, borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CUMULATIVE GPA', style: TextStyle(fontSize: 10.5, letterSpacing: 1, color: Color(0x99F2ECDC))),
                      const SizedBox(height: 4),
                      Text(gpa, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.goldSoft)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL CREDITS', style: TextStyle(fontSize: 10.5, letterSpacing: 1, color: Color(0x99F2ECDC))),
                    const SizedBox(height: 4),
                    Text('${credits.toStringAsFixed(credits % 1 == 0 ? 0 : 1)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textLight)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap a grade pill to cycle through letter grades.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
