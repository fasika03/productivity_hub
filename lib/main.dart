import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/todo_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/gpa_screen.dart';
import 'screens/quotes_screen.dart';

void main() {
  runApp(const ProductivityHubApp());
}

class ProductivityHubApp extends StatelessWidget {
  const ProductivityHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productivity Hub',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootNav(),
    );
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  static const _titles = [
    'To-Do List',
    'Study Planner',
    'Pomodoro Timer',
    'Notes',
    'GPA Calculator',
    'Quotes',
  ];

  static const _screens = [
    TodoScreen(),
    PlannerScreen(),
    TimerScreen(),
    NotesScreen(),
    GpaScreen(),
    QuotesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.inkDarker,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: const Color(0x99F2ECDC),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.check_box_outlined), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Planner'),
          BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), label: 'Timer'),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'GPA'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), label: 'Quotes'),
        ],
      ),
    );
  }
}
