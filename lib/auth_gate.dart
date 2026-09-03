import 'package:flutter/material.dart';
import 'theme.dart';
import 'auth.dart';
import 'screens/lock_screen.dart';

/// Lets any descendant widget trigger a re-lock or ask the gate to refresh
/// its "does a PIN exist" state after the user enables/disables one.
class AuthController extends InheritedWidget {
  final VoidCallback lockNow;
  final Future<void> Function() refresh;

  const AuthController({
    super.key,
    required this.lockNow,
    required this.refresh,
    required super.child,
  });

  static AuthController of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AuthController>();
    assert(result != null, 'No AuthController found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant AuthController oldWidget) => true;
}

/// Wraps the app: shows a PIN lock screen at cold start (if a PIN is set)
/// and again whenever the app returns from the background.
class AuthGate extends StatefulWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _hasPassword = false;
  bool _locked = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    final has = await AuthService().hasPassword();
    if (!mounted) return;
    setState(() {
      _hasPassword = has;
      _locked = has ? _locked : false;
      _loading = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _hasPassword) {
      setState(() => _locked = true);
    }
  }

  void _lockNow() => setState(() => _locked = true);

  void _onUnlocked() => setState(() => _locked = false);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppColors.inkDark, body: SizedBox());
    }
    if (_hasPassword && _locked) {
      return LockScreen(onUnlocked: _onUnlocked);
    }
    return AuthController(
      lockNow: _lockNow,
      refresh: _refresh,
      child: widget.child,
    );
  }
}
