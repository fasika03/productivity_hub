import 'package:flutter/material.dart';
import '../theme.dart';
import '../auth.dart';
import '../auth_gate.dart';
import 'pin_setup_screen.dart';
import 'verify_pin_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _hasPin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final has = await AuthService().hasPassword();
    if (!mounted) return;
    setState(() {
      _hasPin = has;
      _loading = false;
    });
  }

  Future<void> _refreshGate() async {
    if (!mounted) return;
    await AuthController.of(context).refresh();
  }

  Future<void> _enablePin() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
    if (saved == true) {
      await _load();
      await _refreshGate();
      if (mounted) _showSnack('PIN enabled');
    }
  }

  Future<void> _changePin() async {
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const VerifyPinScreen(title: 'Change PIN')),
    );
    if (verified != true || !mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
    if (saved == true && mounted) _showSnack('PIN changed');
  }

  Future<void> _disablePin() async {
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const VerifyPinScreen(title: 'Remove PIN')),
    );
    if (verified != true || !mounted) return;
    await AuthService().removePassword();
    await _load();
    await _refreshGate();
    if (mounted) _showSnack('PIN removed');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(title: const Text('App Lock')),
      body: _loading
          ? const SizedBox()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.parchmentLine),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hasPin ? Icons.lock_outline : Icons.lock_open_outlined,
                        color: _hasPin ? AppColors.sage : AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _hasPin
                              ? 'A PIN is required to open this app.'
                              : 'No PIN set — anyone can open this app.',
                          style: const TextStyle(fontSize: 13.5, color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!_hasPin)
                  ElevatedButton.icon(
                    onPressed: _enablePin,
                    icon: const Icon(Icons.add_moderator_outlined, size: 18),
                    label: const Text('Set up a PIN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.inkDark,
                      foregroundColor: AppColors.textLight,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  )
                else ...[
                  ElevatedButton.icon(
                    onPressed: _changePin,
                    icon: const Icon(Icons.password, size: 18),
                    label: const Text('Change PIN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.inkDark,
                      foregroundColor: AppColors.textLight,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _disablePin,
                    icon: const Icon(Icons.lock_open_outlined, size: 18, color: AppColors.terracotta),
                    label: const Text('Remove PIN', style: TextStyle(color: AppColors.terracotta)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.terracotta),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      AuthController.of(context).lockNow();
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    icon: const Icon(Icons.lock_clock_outlined, size: 18, color: AppColors.textMuted),
                    label: const Text('Lock now', style: TextStyle(color: AppColors.textMuted)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.parchmentLine),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const Text(
                  "If you forget your PIN, the only way back in is uninstalling and "
                  "reinstalling the app — which clears all saved data, since everything "
                  "is stored on-device. Keep that in mind before you set one.",
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                ),
              ],
            ),
    );
  }
}
