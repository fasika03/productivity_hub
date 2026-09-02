import 'package:flutter/material.dart';
import 'theme.dart';
import 'notifications.dart';
import 'screen_time.dart';
import 'screens/todo_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/gpa_screen.dart';
import 'screens/quotes_screen.dart';
import 'screens/screen_time_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
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

class _RootNavState extends State<RootNav> with WidgetsBindingObserver {
  int _index = 0;

  static const _titles = [
    'To-Do List',
    'Study Planner',
    'Pomodoro Timer',
    'Notes',
    'GPA Calculator',
    'Quotes',
  ];

  // Matches the bottom-nav labels; used as the screen-time breakdown keys.
  static const _screenNames = ['Tasks', 'Planner', 'Timer', 'Notes', 'GPA', 'Quotes'];

  static const _screens = [
    TodoScreen(),
    PlannerScreen(),
    TimerScreen(),
    NotesScreen(),
    GpaScreen(),
    QuotesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ScreenTimeTracker().enterScreen(_screenNames[_index]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ScreenTimeTracker().pause();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      ScreenTimeTracker().pause();
    } else if (state == AppLifecycleState.resumed) {
      ScreenTimeTracker().enterScreen(_screenNames[_index]);
    }
  }

  void _selectTab(int i) {
    setState(() => _index = i);
    ScreenTimeTracker().enterScreen(_screenNames[i]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.hourglass_bottom_outlined),
            tooltip: 'Screen time',
            onPressed: () async {
              await ScreenTimeTracker().enterScreen('Screen Time');
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Screen Time')),
                    backgroundColor: AppColors.parchment,
                    body: const ScreenTimeScreen(),
                  ),
                ),
              );
              ScreenTimeTracker().enterScreen(_screenNames[_index]);
            },
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _selectTab,
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
