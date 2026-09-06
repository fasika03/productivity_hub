import 'package:flutter/material.dart';
import '../theme.dart';
import '../storage.dart';

/// Shown once, the first time the app is ever opened (before the lock
/// screen and before the main tabs). Tapping "Get Started" marks onboarding
/// complete so this screen never appears again.
class WelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted;

  const WelcomeScreen({super.key, required this.onGetStarted});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _starting = false;

  Future<void> _handleGetStarted() async {
    if (_starting) return;
    setState(() => _starting = true);
    await Storage.save('onboarding_complete', true);
    if (!mounted) return;
    widget.onGetStarted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 1.6),
                ),
                alignment: Alignment.center,
                child: Text(
                  'PH',
                  style: displayFont(
                      size: 28, weight: FontWeight.w700, color: AppColors.gold),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Productivity Hub',
                style: displayFont(
                    size: 26,
                    weight: FontWeight.w600,
                    color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your all-in-one study companion — tasks, planning,\n'
                'focus timers, notes, GPA tracking, and reminders,\n'
                'all in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, height: 1.6, color: Color(0xB3F2ECDC)),
              ),
              const SizedBox(height: 30),
              _FeatureRow(
                  icon: Icons.check_box_outlined,
                  label: 'Track tasks with reminders'),
              const SizedBox(height: 12),
              _FeatureRow(
                  icon: Icons.timer_outlined,
                  label: 'Stay focused with a Pomodoro timer'),
              const SizedBox(height: 12),
              _FeatureRow(
                  icon: Icons.lock_outline,
                  label: 'Lock the app with a private PIN'),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.inkDarker,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _starting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: AppColors.inkDarker),
                        )
                      : const Text(
                          'Get Started',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.goldSoft),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, color: Color(0xD9F2ECDC)),
          ),
        ),
      ],
    );
  }
}
