import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../storage.dart';
import '../data/quotes.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  late int _index;
  List<Map<String, dynamic>> _favorites = [];
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _index = _rand.nextInt(quotes.length);
    _load();
  }

  Future<void> _load() async {
    final data = await Storage.loadList('favorite-quotes');
    setState(() => _favorites = data);
  }

  Future<void> _persist() async {
    await Storage.save('favorite-quotes', _favorites);
  }

  void _nextQuote() {
    if (quotes.length <= 1) return;
    int next;
    do {
      next = _rand.nextInt(quotes.length);
    } while (next == _index);
    setState(() => _index = next);
  }

  void _saveFavorite() {
    final q = quotes[_index];
    if (!_favorites.any((f) => f['text'] == q['text'])) {
      setState(() => _favorites.add({'text': q['text'], 'author': q['author']}));
      _persist();
    }
  }

  void _removeFavorite(String text) {
    setState(() => _favorites.removeWhere((f) => f['text'] == text));
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final quote = quotes[_index];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.parchmentLine),
          ),
          child: Column(
            children: [
              Text('“', style: displayFont(size: 44, color: AppColors.gold)),
              const SizedBox(height: 4),
              Text(
                quote['text']!,
                textAlign: TextAlign.center,
                style: displayFont(size: 19, weight: FontWeight.w600).copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '— ${quote['author']}',
                style: const TextStyle(fontSize: 12, letterSpacing: 1, color: AppColors.textMuted),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _nextQuote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.inkDark,
                      foregroundColor: AppColors.textLight,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Next quote', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _saveFavorite,
                    icon: const Icon(Icons.favorite_border, size: 15, color: AppColors.textMuted),
                    label: const Text('Save', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.parchmentLine),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Favorites', style: displayFont(size: 15)),
        const SizedBox(height: 10),
        if (_favorites.isEmpty)
          const Text('No favorites saved yet.', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
        else
          ..._favorites.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.parchmentLine),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '"${f['text']}" — ${f['author']}',
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textDark),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeFavorite(f['text'] as String),
                      child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
