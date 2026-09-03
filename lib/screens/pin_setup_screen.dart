import 'package:flutter/material.dart';
import '../theme.dart';
import '../auth.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_keypad.dart';

/// Guides the user through choosing a new 4-digit PIN: enter it once, then
/// confirm by entering it again. Pops with `true` if a PIN was saved.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  static const _pinLength = 4;
  String _firstPin = '';
  String _entered = '';
  bool _confirming = false;
  bool _error = false;

  void _onDigit(String d) {
    if (_entered.length >= _pinLength) return;
    setState(() {
      _entered += d;
      _error = false;
    });
    if (_entered.length == _pinLength) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _handleComplete() async {
    if (!_confirming) {
      setState(() {
        _firstPin = _entered;
        _entered = '';
        _confirming = true;
      });
      return;
    }
    if (_entered == _firstPin) {
      await AuthService().setPassword(_entered);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = true;
        _entered = '';
        _confirming = false;
        _firstPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Set PIN'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                _confirming ? 'Confirm your new PIN' : 'Choose a 4-digit PIN',
                style: displayFont(size: 18, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error ? "PINs didn't match — start again" : 'Used to unlock the app',
                style: TextStyle(
                  fontSize: 13,
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
