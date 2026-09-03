import 'package:flutter/material.dart';
import '../theme.dart';

class PinKeypad extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;

  const PinKeypad({super.key, required this.onDigit, required this.onBackspace});

  Widget _key(String label, {VoidCallback? onTap, Widget? child}) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.5,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: onTap,
              child: Center(
                child: child ??
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          _key('1', onTap: () => onDigit('1')),
          _key('2', onTap: () => onDigit('2')),
          _key('3', onTap: () => onDigit('3')),
        ]),
        Row(children: [
          _key('4', onTap: () => onDigit('4')),
          _key('5', onTap: () => onDigit('5')),
          _key('6', onTap: () => onDigit('6')),
        ]),
        Row(children: [
          _key('7', onTap: () => onDigit('7')),
          _key('8', onTap: () => onDigit('8')),
          _key('9', onTap: () => onDigit('9')),
        ]),
        Row(children: [
          _key('', child: const SizedBox()),
          _key('0', onTap: () => onDigit('0')),
          _key(
            '',
            onTap: onBackspace,
            child: const Icon(Icons.backspace_outlined, size: 20, color: AppColors.textLight),
          ),
        ]),
      ],
    );
  }
}
