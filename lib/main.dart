import 'package:flutter/material.dart';
import 'theme.dart';
import 'notifications.dart';
import 'daily_quote_reminder.dart';
import 'screen_time.dart';
import 'storage.dart';
import 'auth_gate.dart';
import 'screens/todo_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/gpa_screen.dart';
import 'screens/quotes_screen.dart';
import 'screens/translator_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/screen_time_screen.dart';
import 'screens/security_settings_screen.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await DailyQuoteReminder().refreshIfEnabled();
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
      home: const AppRoot(),
    );
  }
}

/// Decides what the person sees first: the one-time "Get Started" welcome
/// screen, or (once that's done) the PIN lock gate wrapping the main app.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final data = await Storage.loadRaw('onboarding_complete');
    if (!mounted) return;
    setState(() => _onboardingComplete = data == true);
  }

  void _completeOnboarding() => setState(() => _onboardingComplete = true);

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return const Scaffold(backgroundColor: AppColors.inkDark, body: SizedBox());
    }
    if (!_onboardingComplete!) {
      return WelcomeScreen(onGetStarted: _completeOnboarding);
    }
    return const AuthGate(child: RootNav());
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
    'Habit Tracker',
  ];

  // Matches the bottom-nav labels; used as the screen-time breakdown keys.
  static const _screenNames = ['Tasks', 'Planner', 'Timer', 'Notes', 'GPA', 'Habits'];

  static const _screens = [
    TodoScreen(),
    PlannerScreen(),
    TimerScreen(),
    NotesScreen(),
    GpaScreen(),
    HabitsScreen(),
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

  Future<void> _openMoreDestination(BuildContext context, String value) async {
    late final String trackingName;
    late final Widget screen;
    switch (value) {
      case 'quotes':
        trackingName = 'Quotes';
        screen = Scaffold(
          appBar: AppBar(title: const Text('Quotes')),
          backgroundColor: AppColors.parchment,
          body: const QuotesScreen(),
        );
        break;
      case 'translator':
        trackingName = 'Translator';
        screen = Scaffold(
          appBar: AppBar(title: const Text('Translator')),
          backgroundColor: AppColors.parchment,
          body: const TranslatorScreen(),
        );
        break;
      case 'app_lock':
        trackingName = 'Security Settings';
        screen = const SecuritySettingsScreen();
        break;
      case 'screen_time':
      default:
        trackingName = 'Screen Time';
        screen = Scaffold(
          appBar: AppBar(title: const Text('Screen Time')),
          backgroundColor: AppColors.parchment,
          body: const ScreenTimeScreen(),
        );
        break;
    }
    await ScreenTimeTracker().enterScreen(trackingName);
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    ScreenTimeTracker().enterScreen(_screenNames[_index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More',
            color: AppColors.parchment,
            onSelected: (value) => _openMoreDestination(context, value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'quotes',
                child: ListTile(
                  leading: Icon(Icons.auto_awesome_outlined, color: AppColors.inkDark),
                  title: Text('Quotes'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'translator',
                child: ListTile(
                  leading: Icon(Icons.translate, color: AppColors.inkDark),
                  title: Text('Translator'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'app_lock',
                child: ListTile(
                  leading: Icon(Icons.lock_outline, color: AppColors.inkDark),
                  title: Text('App Lock'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'screen_time',
                child: ListTile(
                  leading: Icon(Icons.hourglass_bottom_outlined, color: AppColors.inkDark),
                  title: Text('Screen Time'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
          BottomNavigationBarItem(icon: Icon(Icons.local_fire_department_outlined), label: 'Habits'),
        ],
      ),
    );
  }
}
