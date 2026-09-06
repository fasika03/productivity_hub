import 'dart:math';
import 'storage.dart';
import 'notifications.dart';
import 'data/quotes.dart';

/// Manages the "quote of the day" notification: whether it's on, what time
/// it fires, and re-picking a fresh random quote each time it's rescheduled
/// (since a single repeating notification can't change its own text).
class DailyQuoteReminder {
  static const _key = 'daily-quote-reminder';

  Future<Map<String, dynamic>> getSettings() async {
    final data = await Storage.loadMap(_key);
    return {
      'enabled': data['enabled'] as bool? ?? false,
      'hour': data['hour'] as int? ?? 8,
      'minute': data['minute'] as int? ?? 0,
    };
  }

  Future<void> setEnabled(bool enabled, {int hour = 8, int minute = 0}) async {
    await Storage.save(_key, {'enabled': enabled, 'hour': hour, 'minute': minute});
    if (enabled) {
      await _scheduleWithFreshQuote(hour, minute);
    } else {
      await NotificationService().cancel(NotificationService.dailyQuoteNotificationId);
    }
  }

  /// Call at app startup (and it's fine to call again whenever the Quotes
  /// tab opens): re-picks a random quote and reschedules today's/tomorrow's
  /// notification, so it doesn't just repeat the same quote forever.
  Future<void> refreshIfEnabled() async {
    final settings = await getSettings();
    if (settings['enabled'] == true) {
      await _scheduleWithFreshQuote(settings['hour'] as int, settings['minute'] as int);
    }
  }

  Future<void> _scheduleWithFreshQuote(int hour, int minute) async {
    final quote = quotes[Random().nextInt(quotes.length)];
    await NotificationService().scheduleDaily(
      id: NotificationService.dailyQuoteNotificationId,
      title: 'Quote of the day',
      body: '${quote['text']} — ${quote['author']}',
      hour: hour,
      minute: minute,
    );
  }
}
