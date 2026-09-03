import 'package:flutter/material.dart';
import '../theme.dart';
import '../auth.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_keypad.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  static const _pinLength = 4;
  String _entered = '';
  bool _error = false;
  bool _checking = false;

  void _onDigit(String d) {
    if (_checking || _entered.length >= _pinLength) return;
    setState(() {
      _entered += d;
      _error = false;
    });
    if (_entered.length == _pinLength) {
      _verify();
    }
  }

  void _onBackspace() {
    if (_checking || _entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _verify() async {
    setState(() => _checking = true);
    final ok = await AuthService().verifyPassword(_entered);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = true;
        _entered = '';
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 1.6),
                ),
                alignment: Alignment.center,
                child: Text(
                  'PH',
                  style: displayFont(size: 22, weight: FontWeight.w700, color: AppColors.gold),
                ),
              ),
              const SizedBox(height: 18),
              Text('Productivity Hub', style: displayFont(size: 20, color: AppColors.textLight)),
              const SizedBox(height: 8),
              Text(
                _error ? 'Incorrect PIN — try again' : 'Enter your PIN',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 0.5,
                  color: _error ? AppColors.terracotta : const Color(0x99F2ECDC),
                ),
              ),
              const SizedBox(height: 28),
              PinDots(length: _pinLength, filled: _entered.length, error: _error),
              const Spacer(flex: 2),
              PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
