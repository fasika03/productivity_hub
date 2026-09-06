import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:translator/translator.dart';
import '../theme.dart';

class _Lang {
  final String code;
  final String name;
  const _Lang(this.code, this.name);
}

const List<_Lang> _languages = [
  _Lang('en', 'English'),
  _Lang('es', 'Spanish'),
  _Lang('fr', 'French'),
  _Lang('de', 'German'),
  _Lang('it', 'Italian'),
  _Lang('pt', 'Portuguese'),
  _Lang('ru', 'Russian'),
  _Lang('zh-cn', 'Chinese (Simplified)'),
  _Lang('ja', 'Japanese'),
  _Lang('ko', 'Korean'),
  _Lang('ar', 'Arabic'),
  _Lang('hi', 'Hindi'),
  _Lang('tr', 'Turkish'),
  _Lang('nl', 'Dutch'),
  _Lang('pl', 'Polish'),
  _Lang('vi', 'Vietnamese'),
  _Lang('th', 'Thai'),
  _Lang('sv', 'Swedish'),
  _Lang('el', 'Greek'),
  _Lang('he', 'Hebrew'),
  _Lang('am', 'Amharic'),
  _Lang('sw', 'Swahili'),
];

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final _inputController = TextEditingController();
  final _translator = GoogleTranslator();

  String _fromCode = 'auto';
  String _toCode = 'en';
  String _resultText = '';
  String? _detectedFrom;
  bool _loading = false;
  String? _error;

  String _langName(String code) {
    if (code == 'auto') return 'Detect language';
    return _languages.firstWhere((l) => l.code == code, orElse: () => _Lang(code, code)).name;
  }

  Future<void> _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _resultText = '';
      _detectedFrom = null;
    });
    try {
      final translation = await _translator.translate(text, from: _fromCode, to: _toCode);
      if (!mounted) return;
      setState(() {
        _resultText = translation.text;
        _detectedFrom = _fromCode == 'auto' ? translation.sourceLanguage.name : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't translate that — check your internet connection and try again.";
        _loading = false;
      });
    }
  }

  void _swapLanguages() {
    if (_fromCode == 'auto') return;
    setState(() {
      final tempCode = _fromCode;
      _fromCode = _toCode;
      _toCode = tempCode;
      final tempText = _inputController.text;
      _inputController.text = _resultText;
      _resultText = tempText;
    });
  }

  void _copyResult() {
    if (_resultText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _resultText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _pickLanguage({required bool isSource}) async {
    final options = isSource
        ? [const _Lang('auto', 'Detect language'), ..._languages]
        : _languages;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.parchment,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: options
                .map((l) => ListTile(
                      title: Text(l.name, style: const TextStyle(fontSize: 14.5)),
                      trailing: (isSource ? _fromCode : _toCode) == l.code
                          ? const Icon(Icons.check, color: AppColors.gold, size: 18)
                          : null,
                      onTap: () => Navigator.of(context).pop(l.code),
                    ))
                .toList(),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        if (isSource) {
          _fromCode = selected;
        } else {
          _toCode = selected;
        }
      });
    }
  }

  Widget _langButton({required bool isSource}) {
    final code = isSource ? _fromCode : _toCode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickLanguage(isSource: isSource),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.parchmentLine),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _langName(code),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _langButton(isSource: true),
              IconButton(
                onPressed: _fromCode == 'auto' ? null : _swapLanguages,
                icon: Icon(
                  Icons.swap_horiz,
                  color: _fromCode == 'auto' ? AppColors.parchmentLine : AppColors.textMuted,
                ),
              ),
              _langButton(isSource: false),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _inputController,
            maxLines: 5,
            minLines: 4,
            decoration: const InputDecoration(hintText: 'Type text to translate…'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _translate,
              icon: _loading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textLight),
                    )
                  : const Icon(Icons.translate, size: 18),
              label: Text(_loading ? 'Translating…' : 'Translate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.inkDark,
                foregroundColor: AppColors.textLight,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.terracotta),
              ),
              child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.terracotta)),
            )
          else if (_resultText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.parchmentLine),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_detectedFrom != null)
                        Expanded(
                          child: Text(
                            'Detected: $_detectedFrom',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        const Spacer(),
                      IconButton(
                        onPressed: _copyResult,
                        icon: const Icon(Icons.copy_outlined, size: 17, color: AppColors.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    _resultText,
                    style: const TextStyle(fontSize: 16, color: AppColors.textDark, height: 1.4),
                  ),
                ],
              ),
            ),
          const Spacer(),
          const Text(
            'Uses a free translation service and needs an internet connection — '
            'unlike the rest of Productivity Hub, this tool isn\'t fully offline.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
