import 'package:flutter/material.dart';
import '../theme.dart';
import '../auth.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_keypad.dart';

/// Asks for the current PIN and pops with `true` once it's verified correct.
class VerifyPinScreen extends StatefulWidget {
  final String title;

  const VerifyPinScreen({super.key, this.title = 'Enter current PIN'});

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
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
    if (_entered.length == _pinLength) _verify();
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
      Navigator.of(context).pop(true);
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text(widget.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                _error ? 'Incorrect PIN — try again' : 'Enter your current PIN to continue',
                style: TextStyle(
                  fontSize: 14,
                  color: _error ? AppColors.terracotta : AppColors.textLight,
                ),
                textAlign: TextAlign.center,
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
